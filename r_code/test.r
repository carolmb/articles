library("segmented")
library(Metrics)
traceback()

# p-value for breakpoints
# order by mse

fileName <- "../data/plos_one_2019.txt"
conn <- file(fileName,open="r")
linn <-readLines(conn)
data<-vector("list",length(linn)/3)

global_valid_curves <- 0
global_invalid_curves <- 0

data_index <- 1
for (i in seq(1,length(linn),by=3)){
  doi<-linn[i]
  months<-as.numeric(strsplit(linn[i+1],',')[[1]])
  views<-as.numeric(strsplit(linn[i+2],',')[[1]])
  if (data_index == 139 || data_index == 140 || data_index == 141) {
  	print(months)
  	print(length(months))
  	print(views)
  	print(length(views))
  	pdf(paste(data_index,'.pdf'))
	plot(months,views)
	#lines(months,views)
	dev.off()
  }
  data[[data_index]]<-list(doi=doi,months=months,views=views)
  data_index <- data_index + 1
}

normalize <- function(x) {
	temp <- ((x - min(x)) / (max(x) - min(x)))
	return (temp)
}

get_segmented <- function(dati,doi,filename_curves,filename_mse,itmax,k,stopiferror,nboot,yy,i,xx) {
	result <- tryCatch({

	    out.lm<-lm(y~x,data=dati)
	    o<-segmented(out.lm, seg.Z=~x, psi=NA, control=seg.control(it.max=itmax, display=FALSE,K=k, stop.if.error=stopiferror, n.boot=nboot))
		y.mse <- mse(yy,broken.line(o,link=FALSE)$fit)
		write(y.mse,file = filename_mse, append=TRUE)
		
		if (y.mse >= 0.0001) {
			global_invalid_curves <<- global_invalid_curves + 1
		# y.mape <- mape(yy,broken.line(o,link=FALSE)$fit)
		# if (y.mape >= 0.02) {
		# 	# jpeg(paste('ge/',i))
		# 	# plot(o)
			
		# 	# lines(xx,yy,col='green')
		# 	# dev.off()
		# 	print('if')
		 } else {
			# print(global_valid_curves)
			
			global_valid_curves <<- global_valid_curves + 1

			slopes<-slope(o)$x[,1]

			breakpoints<-o$psi[,2]
			pred<-predict(o)
			write(doi, file = filename_curves, append = TRUE)
			write.table(t(slopes), file = filename_curves, append = TRUE, col.names=FALSE, row.names=FALSE)
			write.table(t(breakpoints), file = filename_curves, append = TRUE, col.names=FALSE, row.names=FALSE)
			write.table(t(pred), file = filename_curves, append = TRUE, col.names=FALSE, row.names=FALSE)
			
		}

		return (o)

	}, error = function(e) {
		print("-----------------------------------------------")
		print(i)
		#print(paste("dati:", dati))
		print(paste("MY_ERROR:  ",e))
		#print(paste("Line: ", out.lm))
		#traceback()
		#browser()
		print("-----------------------------------------------")
		return ('')
	})
	return (result)
}

tests <- function(itmax,k,stopiferror) {
	# filename <- paste("../data/plos_one_2019_breakpoints_k4_original1_data.txt",sep="")
	filename <- "segmented_curves.txt"
	filename_mse <- "mse_curves.txt"
	conn <- file(filename,open="w")
	close(conn)
	conn2 <- file(filename_mse,open="w")
	close(conn2)
  
	nboot <- 0
	if (stopiferror) {
		nboot <- 5
	}
	vector.mse <- c()
	vector.p.value <- c()
	#for (i in seq(1,length(linn)/3)){
	for (i in seq(1,length(linn)/3)) {
		if (i%%1000==0){
		  print(i)
		}
        
		xx<-data[[i]]$months[2:length(data[[i]]$months)]
		yy<-data[[i]]$views[2:length(data[[i]]$views)]

		xx<-normalize(xx)
		yy<-normalize(yy)
		
		dati<-data.frame(x=xx,y=yy) 

		y<-get_segmented(dati,doi=data[[i]]$doi,filename,filename_mse,itmax,k,stopiferror,nboot,yy,i,xx)
    }
}


# tests(100,3,FALSE)
# [1] 16
# [1] 946
# [1] 87
# [1] 9913
# [1] -0.02208008


# tests(100,5,FALSE)
# [1] 5
# [1] 346
# [1] 87
# [1] 9913
# [1] -0.01375302

# tests(100,4,FALSE)
# [1] 4
# [1] 570
# [1] 87
# [1] 9913
# [1] -0.004059659

# tests(500,4,FALSE)
# tests(300,4,FALSE)

tests(100,4,FALSE)
print(global_valid_curves)
print(global_invalid_curves)
# tests(500,4,TRUE)
# tests(300,4,TRUE)

# total 10000
# [1] 87 <- casos em que supostamente não tem breakpoint
# [1] 9913

# data/breakpoints_k3it.max100stop.if.errorFALSE.txt
# 0.000109 0.000196
# data/breakpoints_k4it.max1000stop.if.errorFALSE.txt
# 0.000144 0.000511
# data/breakpoints_k4it.max100stop.if.errorFALSE.txt
# 0.000092 0.000205
# data/breakpoints_k4it.max100stop.if.errorTRUE.txt
# 0.000054 0.000108
# data/breakpoints_k4it.max300stop.if.errorFALSE.txt
# 0.000110 0.000289
# data/breakpoints_k4it.max300stop.if.errorTRUE.txt
# 0.000052 0.000071
# data/breakpoints_k4it.max500stop.if.errorFALSE.txt
# 0.000110 0.000289
# data/breakpoints_k4it.max500stop.if.errorTRUE.txt
# 0.000053 0.000091
# data/breakpoints_k5it.max100stop.if.errorFALSE.txt
# 0.000075 0.000160
# data/breakpoints_k6it.max100stop.if.errorFALSE.txt
# 0.000076 0.000270



# total 162534
# validos 129872
# invalidos 31995
# problemas 667