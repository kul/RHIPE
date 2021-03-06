#' Initialize Rhipe
#'
#' Necessary to call before using Rhipe.  Rhipe likely will not work if any
#' functions in the package are called before this.  Generally, a user just
#' calls it with default arguments as \code{rhinit()}.
#' 
#' @param errors If TRUE errors are printed to the display.
#' @param info If TRUE reports command line information related to how it is starting Rhipe PersonalServer.
#' @param path Depreciated. Still used internally.
#' @param cleanup Force the shutdown of Rhipe's Java server on garbage collection of rhoptions()$child$handle?  Not really needed can leave FALSE.
#' @param bufsize Size of buffer from which data is sent to and from hadoop
#'   client.
#' @param buglevel The higher the number the more information that is outputted
#'   during Rhipe operations. Currently 2000 prints all information.
#' @param first Deprecated. Still used internally.
#' @return TRUE if successful
#' @author Saptarshi Guha
#' @seealso \code{\link{rhoptions}}
#' @examples
#' 
#' 	# rhinit()   #typical use in day to day Rhipe
#' 	# prints a slew of information; sometimes useful if Rhipe is not installed correctly.
#' 	# rhinit(TRUE,TRUE,buglevel=2000) 
#' @export
rhinit <-function(errors=TRUE,buglevel=0,info=FALSE,path=NULL,cleanup=FALSE,bufsize=as.integer(3*1024*1024),first=TRUE){
  ## for debug: rhinit(errors=TRUE,info
  Rhipe:::.rhinit(errors,info,path,cleanup,bufsize,buglevel)
  if(first){
    ## if(buglevel>0) message("Initial call to personal server")
    ## Rhipe:::.rhinit(errors=TRUE,info=if(buglevel) TRUE else FALSE,path,cleanup,bufsize,buglevel=buglevel)
    rhoptions(mode = Rhipe:::Mode,mropts=rhmropts(),quiet=FALSE) # "experimental"
    ## if(buglevel>0) message("Secondary call to personal server")
    ## Rhipe:::.rhinit(errors=TRUE,info=if(buglevel) TRUE else FALSE,path,cleanup,bufsize,buglevel=buglevel)
    Sys.sleep(2)
    message("Rhipe first run complete")
    message("Initializing mapfile caches")
    rh.init.cache()
    return(TRUE)
  }
  message("Initializing mapfile caches")
  rh.init.cache()
}


.rhinit <- function(errors=FALSE, info=FALSE,path=NULL,cleanup=FALSE,bufsize=as.integer(3*1024*1024),buglevel=0){


  Sys.setenv(HADOOP_CLASSPATH=sprintf("%s:%s", Sys.getenv("HADOOP_CLASSPATH"),paste(rhoptions()$mycp,collapse=":")))
  rhoptions(.code.in=sample(1e6,1))
  ntimeout <- options("timeout")[[1]]
  options(timeout = if(!is.null(rhoptions()$timeout)) as.integer(rhoptions()$timeout) else 15552000L)
  on.exit({
    options(timeout = ntimeout)
    unlink(r)
    unlink(r2)
  })  
  

  f1 <- "localhost"
  r <- tempfile(pattern="sockets");r2 <- tempfile(pattern="signal")
  if(is.null(path))
    cmda <- paste( c(sprintf("%s/hadoop jar",Sys.getenv("HADOOP_BIN")),rhoptions()$jarloc,"org.godhuli.rhipe.PersonalServer",f1,r,r2,as.integer(buglevel)),collapse=" ")
  else cmda <- path
  if(info){
    message(cmda)
  }

  
  
	################################################################################################
	# Right before creating a new java process at this point so trying to shut down what we already have
	################################################################################################
	try({killServer(rhoptions()$child$handle)},silent=TRUE)
	################################################################################################
	# Now making a new one
	################################################################################################

  j <- .Call("createProcess", cmda, c(as.integer(errors),as.integer(info)),as.integer(bufsize),as.integer(buglevel),PACKAGE="Rhipe")
  ## This is a potential race here, the child starts the Java server
  ## but before it even starts we arrive here ...
  ## so we busy wait
  ## to fix this I simply need to read from the Java standard output.
  ## will implement one day
  while(TRUE){
    if(!is.na(file.info(r2)[1,]$size)){
      if(buglevel>1000) message(sprintf("Found signal file (created by personalserver): %s",r2))
      break
    }
  }
  x <- read.table(r,head=TRUE)
  y <- new.env()
  y$ports <- x
  y$tojava <- socketConnection(f1,as.numeric(y$ports['fromR']),open='wb',blocking=TRUE)
  y$fromjava <- socketConnection(f1,as.numeric(y$ports['toR']),open='rb',blocking=TRUE)
  y$err <- socketConnection(f1,as.numeric(y$ports['err']),open='rb',blocking=TRUE)
  y$killed = FALSE     

  reg.finalizer(y, function(r){
    if(cleanup) {
      if(!is.null(rhoptions()$quiet) && !rhoptions()$quiet)
         
      	## tryCatch({writeBin(as.integer(-1),con=r$tojava,endian="big")},error=function(e) {},warning=function(e){})
      	killServer(r)
    }
  },onexit=TRUE)
  if(is.null(errors)) errors <- FALSE
  if(is.null(info)) info <- FALSE
  message("Rhipe initialization complete")
  rhoptions(child=list(errors=errors,info=info,handle=y,bufsize=bufsize))
}
