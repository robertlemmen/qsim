#!/usr/bin/Rscript

pdf(file='01-events.pdf',width=16, height=10)

poisson_events <- read.table("poisson-events.data")
random_events <- read.table("random-events.data")
even_events <- read.table("normal-events.data")
plot(poisson_events$V1, poisson_events$V1 / poisson_events$V1 / 2, type='h', xlab='', ylab='', yaxt='n', ylim=c(0,1.5), xlim=c(0,2000), col=c('#2a8592'), lwd="2", xaxt='n', bty="n")
par(new=TRUE)
segments(random_events$V1, 0.5, random_events$V1, 1, type='h', xlab='', ylab='', yaxt='n', ylim=c(0,1.5), xlim=c(0,2000), col=c('#922a85'), xaxt='n', lwd=2)
segments(even_events$V1, 1, even_events$V1, 1.5, type='h', xlab='', ylab='', yaxt='n', ylim=c(0,1.5), xlim=c(0,2000), col=c('#2a9236'), xaxt='n', lwd=2)

dev.off()


pdf(file='01-histogram.pdf',width=16, height=10)

poisson_hist <- read.table("poisson-hist.data")
random_hist <- read.table("random-hist.data")
even_hist <- read.table("normal-hist.data")
plot(poisson_hist, xlab='', ylab='', yaxt='n', type='l', ylim=c(0,10000), xlim=c(3,130), col=c('#2a8592'), lwd="2", xaxt='n', bty="n")
par(new=TRUE)
plot(random_hist, xlab='', ylab='', yaxt='n', type='l', ylim=c(0,10000), xlim=c(3,130), col=c('#922a85'), lwd="2", xaxt='n', bty="n")
par(new=TRUE)
plot(even_hist, xlab='', ylab='', yaxt='n', type='l', ylim=c(0,10000), xlim=c(3,130), col=c('#2a9236'), lwd="2", xaxt='n', bty="n")

dev.off()
