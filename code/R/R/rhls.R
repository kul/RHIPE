#' List Files On HDFS
#'
#' List all files and directories contained in a directory on the HDFS.
#' 
#' @param folder  Path of directory on HDFS or output from rhmr or rhwatch(read=FALSE)
#' @param recurse If TRUE list all files and directories in sub-directories.
#' @author Saptarshi Guha
#' @details Returns a data.frame of filesystem information for the files located
#'   at \code{path}. If \code{recurse} is TRUE, \code{rhls} will recursively
#'   travel the directory tree rooted at \code{path}. The returned object is a
#'   data.frame consisting of the columns: \emph{permission, owner, group, size
#'   (which is numeric), modification time}, and the \emph{file name}.
#'   \code{path} may optionally end in `*' which is the wildcard and will match
#'   any character(s).
#' @return vector of file and directory names
#' @seealso \code{\link{rhput}}, \code{\link{rhdel}},
#'   \code{\link{rhread}}, \code{\link{rhwrite}},
#'   \code{\link{rhsave}}, \code{\link{rhget}}
#' @keywords list HDFS directory
#' @export
rhls <- function(folder,recurse=FALSE){
	## List of files,
  if( is(folder,"rhmr") || is(folder, "rhwatch"))
    folder <- rhofolder(folder)
  folder <- rhabsolute.hdfs.path(folder)
  v <- Rhipe:::send.cmd(rhoptions()$child$handle,list("rhls",folder, if(recurse) 1L else 0L))
  if(is.null(v)) return(NULL)
                                        #condition nothing in the directory?
  if(length(v) == 1  && length(v[[1]]) == 0){
    f = as.data.frame(matrix(0,0,6))
  } else {
    f <- as.data.frame(do.call("rbind",sapply(v,strsplit,"\t")),stringsAsFactors=F)
  }
  rownames(f) <- NULL
  colnames(f) <- c("permission","owner","group","size","modtime","file")
  f$size <- as.numeric(f$size)
  unique(f)
}

# rhls <- function(fold,recurse=FALSE,ignore.stderr=T,verbose=F){
#   ## List of files,
#   v <- Rhipe:::doCMD(rhoptions()$cmd['ls'],fold=fold,recur=as.integer(recurse),needoutput=T,ignore.stderr=ignore.stderr,verbose=verbose)
#   if(is.null(v)) return(NULL)
#   if(length(v)==0) {
#     warning(sprintf("Is not a readable directory %s",fold))
#     return(v)
#   }
#   ## k <- strsplit(v,"\n")[[1]]
#   ## k1 <- do.call("rbind",sapply(v,strsplit,"\t"))
#   f <- as.data.frame(do.call("rbind",sapply(v,strsplit,"\t")),stringsAsFactors=F)
#   rownames(f) <- NULL
#   colnames(f) <- c("permission","owner","group","size","modtime","file")
#   f$size <- as.numeric(f$size)
#   unique(f)
# }
