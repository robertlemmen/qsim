#!/usr/bin/Rscript

pdf(file='02-simple-queue.pdf',width=16, height=10)

simple_queue <- read.table("simple-queue.data", header = TRUE)

plot(simple_queue$time, simple_queue$q1_mean, xlab='', ylab='', type='l',  col=c('#2a8592'), lwd="2", xaxt='n', xlim=c(0,10000), bty="n")
par(new=TRUE)
plot(simple_queue$time, simple_queue$p1_mean, xlab='', ylab='', type='l', ylim=c(0,1), col=c('#922a85'), lwd="2", xaxt='n', yaxt='n', xlim=c(0,10000), bty="n")
axis(4, at=c(0,1),labels=c(0,1), las=2)

dev.off()

pdf(file='02-simple-queue-2.pdf',width=16, height=10)

simple_queue <- read.table("simple-queue-2.data", header = TRUE)

plot(simple_queue$time, simple_queue$q1_mean, xlab='', ylab='', type='l', ylim=c(0,5), col=c('#2a8592'), lwd="2", xaxt='n', xlim=c(0,10000), bty="n")
arrows(simple_queue$time, simple_queue$q1_mean-simple_queue$q1_dev, simple_queue$time, simple_queue$q1_mean+simple_queue$q1_dev, length=0.0, angle=90, code=2, col=c('#2a859240'), xlim=c(0,10000))
par(new=TRUE)
plot(simple_queue$time, simple_queue$p1_mean, xlab='', ylab='', type='l', ylim=c(0,1), col=c('#922a85'), lwd="2", xaxt='n', yaxt='n', xlim=c(0,10000), bty="n")
arrows(simple_queue$time, simple_queue$p1_mean-simple_queue$p1_dev, simple_queue$time, simple_queue$p1_mean+simple_queue$p1_dev, length=0.0, angle=90, code=2, col=c('#922a8540'), xlim=c(0,10000))

axis(4, at=c(0,1),labels=c(0,1), las=2)

dev.off()

pdf(file='02-simple-queue-3.pdf',width=16, height=10)

simple_queue <- read.table("simple-queue-3.data", header = TRUE)

plot(simple_queue$time, simple_queue$q1_mean, xlab='', ylab='', type='l', ylim=c(0,5), col=c('#2a8592'), lwd="2", xaxt='n', xlim=c(0,10000), bty="n")
arrows(simple_queue$time, simple_queue$q1_mean-simple_queue$q1_dev, simple_queue$time, simple_queue$q1_mean+simple_queue$q1_dev, length=0.0, angle=90, code=2, col=c('#2a859240'), xlim=c(0,10000))
par(new=TRUE)
plot(simple_queue$time, simple_queue$p1_mean, xlab='', ylab='', type='l', ylim=c(0,8), col=c('#922a85'), lwd="2", xaxt='n', yaxt='n', xlim=c(0,10000), bty="n")
arrows(simple_queue$time, simple_queue$p1_mean-simple_queue$p1_dev, simple_queue$time, simple_queue$p1_mean+simple_queue$p1_dev, length=0.0, angle=90, code=2, col=c('#922a8540'), xlim=c(0,10000))
axis(4, at=c(0,2,4,6,8),labels=c(0,2,4,6,7), las=2)

dev.off()



