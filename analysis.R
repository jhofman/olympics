require(ggplot2)
require(plyr)
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

# restrict to final heats
finals <- transform(subset(records, grepl('^Final', phase)),
                    event=sub('-final(-round)?$', '', phase.id))

# restrict to track races
events <- c('mens-100-metres',
            'mens-200-metres',
            'mens-400-metres',
            'mens-800-metres',
            'mens-1500-metres',
            'mens-5000-metres',
            'mens-10000-metres')
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
ggsave(p, file='figures/track_event_times_by_year.pdf', width=16, height=9)
p

# plot medalist speeds by year
p <- ggplot(data=plot.data, aes(x=year, y=mph, color=event))
p <- p + geom_point()
p <- p + geom_smooth(method="lm", formula=y ~ poly(x,2), alpha=0.1)
ggsave(p, file='figures/track_event_speeds_by_year.pdf', width=16, height=9)
p
