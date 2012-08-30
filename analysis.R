require(ggplot2)
require(plyr)
library(scales)
theme_set(theme_bw())

# helper function to pad times to HH:MM:SS
pad.time <- function(time) {
  parts <- length(unlist(strsplit(time,':')))
  if (parts == 1)
    time <- sprintf("00:00:%s", time)
  else if (parts == 2)
    time <- sprintf("00:%s", time)
  time
}

# read medalists from various sports
sports <- c('ath','swi')
medalists <- adply(sports, 1, function(sport) {
  read.delim(sprintf('%s_medalists.tsv', sport), sep='\t', header=F,
             col.names=c('year','event','country','athlete','athlete.id','athlete.url'))
})
medalists <- transform(medalists[,1:6],
                       sport=sports[X1])

# read time and distance records
records <- read.delim('records.tsv', sep='\t', header=F,
                      col.names=c('year','athlete.id','age','phase','phase.id','rank','misc','time','distance'))
records <- transform(records,
                     misc=ifelse(misc=="None", NA, as.character(misc)),
                     time=ifelse(time=="None" | time=="", NA, as.character(time)),
                     distance=ifelse(distance=="None" | distance =="", NA, as.character(distance)))


# function to plot final events
plot.finals <- function(medalists, records, events, file.prefix) {
  
  # restrict to final heats
  finals <- transform(subset(records, grepl('^Final', phase)),
                      event=sub('-final(-round)?$', '', phase.id))

  # restrict to given events
  final.races <- subset(finals, event %in% events)

  # join medalists with times
  final.races <- merge(medalists, final.races,
                       by.x=c('event','athlete.id','year'),
                       by.y=c('event','athlete.id','year'))

  # remove non-numeric characters from time and rank
  final.races <- transform(final.races,
                           time=sub('[^0-9]*$', '', time),
                           rank=sub('[^0-9]*$', '', rank))

  # restrict to reasonable times (> 5 seconds) and convert to POSIXct
  final.races <- subset(final.races, !is.na(time) & as.numeric(sub(':','',time)) > 5)
  final.races$time <- as.POSIXct(sapply(final.races$time, pad.time),
                                 format="%H:%M:%OS")

  # compute distances and speeds
  final.races$meters <- as.numeric(gsub('[^0-9]*', '', final.races$event))
  final.races$sec <- as.numeric(final.races$time -
                                as.POSIXct(strftime(Sys.time(), format="%Y-%m-%d")))
  final.races <- transform(final.races,
                           mps=meters/sec,
                           mph=meters/sec*3600/1609)

  # plot medalist times for each event
  plot.data <- final.races
  plot.data$event <- factor(as.character(plot.data$event), levels=events)
  plot.data$rank <- factor(plot.data$rank, labels=c('gold','silver','bronze'))
  p <- ggplot(data=plot.data, aes(x=year, y=time, color=rank))
  p <- p + geom_point()
  p <- p + geom_smooth(method="lm", formula=y ~ poly(x,2), alpha=0.1)
  p <- p + scale_y_datetime()
  p <- p + scale_colour_manual(values=c("#FFD700", "#BFC1C2", "#C9AE5D"))
  p <- p + facet_wrap(~ event, ncol=4, scales="free_y")
  ggsave(p, file=sprintf('figures/%s_times_by_year.pdf', file.prefix), width=16, height=9)
  p


  # plot percent slower than current
  plot.data <- ddply(plot.data, "event", function(df) {
    df$percent.slower <- df$sec/min(df$sec)-1
    df
  })
  p <- ggplot(data=plot.data, aes(x=year, y=percent.slower, color=rank))
  p <- p + geom_point()
  #p <- p + geom_smooth(method="lm", formula=y ~ poly(x,2), alpha=0.1)
  p <- p + scale_y_continuous(labels=percent_format())
  p <- p + scale_colour_manual(values=c("#FFD700", "#BFC1C2", "#C9AE5D"))
  p <- p + facet_wrap(~ event, ncol=4)
  ggsave(p, file=sprintf('figures/%s_percent_slower_by_year.pdf', file.prefix), width=16, height=9)
  p
  
  # plot medalist speeds by year
  p <- ggplot(data=plot.data, aes(x=year, y=mph, color=event))
  p <- p + geom_point()
  p <- p + geom_smooth(method="lm", formula=y ~ poly(x,2), alpha=0.1)
  ggsave(p, file=sprintf('figures/%s_speeds_by_year.pdf', file.prefix), width=16, height=9)
  p

  # plot medalist speeds by distance
  p <- ggplot(data=subset(plot.data, year >= 2000), aes(x=meters, y=mph))
  p <- p + geom_point()
  p <- p + geom_smooth(method="lm", formula=y ~ poly(log2(x),2), alpha=0.1)
  #p <- p + scale_x_log10()
  ggsave(p, file=sprintf('figures/%s_speeds_by_distance.pdf', file.prefix), width=16, height=9)
  p

}


events <- c('mens-100-metres',
            'mens-200-metres',
            'mens-400-metres',
            'mens-800-metres',
            'mens-1500-metres',
            'mens-5000-metres',
            'mens-10000-metres')
plot.finals(medalists, records, events, 'mens_track')


events <- c('mens-100-metres-freestyle',
            'mens-100-metres-butterfly',
            'mens-200-metres-freestyle',
            'mens-200-metres-butterfly',
            'mens-200-metres-individual-medley',
            'mens-400-metres-freestyle',
            'mens-400-metres-individual-medley',
            'mens-1500-metres-freestyle'
            )
plot.finals(medalists, records, events, 'mens_swimming')

