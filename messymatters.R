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
             col.names=c('year','event','medal','country','athlete','athlete.id','athlete.url'))
})
medalists <- transform(medalists[,1:7],
                       sport=sports[X1])

# read time and distance records
records <- read.delim('records.tsv', sep='\t', header=F,
                      col.names=c('year','athlete.id','age','phase','phase.id','rank','misc','time','distance'))
records <- transform(records,
                     misc=ifelse(misc=="None", NA, as.character(misc)),
                     time=ifelse(time=="None" | time=="", NA, as.character(time)),
                     distance=ifelse(distance=="None" | distance =="", NA, as.character(distance)),
                     event=sub('-(final|round)[a-z-]*$', '', phase.id))

# extract sex, unisex event name, time and distance
records <- transform(records,
                     sex=gsub('^(w?o?men).*$','\\1', event),
                     event.unisex=gsub('^w?o?mens-(.*)$','\\1', event),
                     time.posix=as.POSIXct(sapply(time, pad.time), format="%H:%M:%OS"),
                     meters=as.numeric(gsub('[^0-9]*', '', event)))

# convert posix time to seconds
records <- transform(records,
                     sec=as.numeric(time.posix - as.POSIXct(strftime(Sys.time(), format="%Y-%m-%d"))))

# calculate speeds
records <- transform(subset(records, sec >= 5),
                     mps=meters/sec,
                     mph=meters/sec*3600/1609)

# restrict to final heats, reasonable times (>= 5 seconds), and medalists
finals <- subset(records, grepl('^Final', phase))
finals <- subset(finals, as.numeric(sub(':','',time)) > 5 & rank %in% c("1","2","3"))
finals <- merge(finals, medalists, by=c('event','athlete.id','year'))



# plot percent slower than best time for men's track
events <- c('mens-100-metres',
            'mens-800-metres',
            'mens-1500-metres')
plot.data <- subset(finals, event %in% events)
plot.data <- ddply(plot.data, "event", function(df) {
  df$percent.slower <- df$sec/min(df$sec)-1
  df
})
plot.data <- transform(plot.data, event=reorder(event, meters))
p <- ggplot(data=plot.data, aes(x=year, y=percent.slower, color=rank))
p <- p + geom_point()
#p <- p + geom_smooth(method="lm", formula=y ~ poly(x,2), alpha=0.1)
p <- p + scale_y_continuous(labels=percent_format())
p <- p + scale_colour_manual(values=c("#FFD700", "#BFC1C2", "#C9AE5D"))
p <- p + facet_wrap(~ event, ncol=3)
p <- p + opts(legend.position="none")
p <- p + xlab('') + ylab('Percent slower than fastest time')
ggsave(p, file='figures/mens_track_percent_slower_by_year.png', width=8, height=4)
p


# plot medalist speeds by year
events.unisex <- c('100-metres',
                   '200-metres',
                   '400-metres',
                   '800-metres',
                   '1500-metres',
                   '5000-metres',
                   '10000-metres')
plot.data <- subset(finals, event.unisex %in% events.unisex & year >= 1948 & rank == 1)
plot.data <- transform(plot.data, event.unisex=reorder(event.unisex, meters))
p <- ggplot(data=plot.data, aes(x=year, y=mph, color=event.unisex))
p <- p + geom_point()
p <- p + facet_wrap(~ sex)
p <- p + opts(legend.title=theme_blank())
p <- p + geom_smooth(method="lm", formula=y ~ poly(x,2), alpha=0.1)
p <- p + xlab('') + ylab('Miles per hour')
ggsave(p, file='figures/track_speeds_by_year.png', width=8, height=4)
p


# compute ratio of male to female times
golds <- subset(finals, rank==1)
men.vs.women <- merge(golds, golds,
                      by=c("year", "sport", "event.unisex", "rank", "meters"),
                      suffixes=c('.men','.women'))
men.vs.women <- subset(men.vs.women, sex.men=='men' & sex.women=='women')
men.vs.women <- transform(men.vs.women, male.female.ratio=mph.men/mph.women)

# male.female.ratio for each track event
events.unisex <- c('100-metres',
                   #'200-metres',
                   #'400-metres',
                   '800-metres',
                   '1500-metres')
                   #'5000-metres',
                   #'10000-metres')
plot.data <- subset(men.vs.women, event.unisex %in% events.unisex & year >= 1948 & !is.na(meters) & !is.na(male.female.ratio) & sport=='ath')
plot.data <- transform(plot.data, event.unisex=reorder(event.unisex, meters))
p <- ggplot(data=plot.data, aes(x=year, y=male.female.ratio-1))
p <- p + geom_point()
p <- p + facet_wrap(~ event.unisex, nrow=1)
p <- p + scale_y_continuous(labels=percent_format(), limits=c(0.05,0.20))
p <- p + ylab('Relative speed\n(men to women)')
p <- p + opts(axis.text.x=theme_text(angle=45, hjust=1, vjust=1))
ggsave(p, file='figures/track_men_vs_women_by_year.png', width=8, height=2)
p

