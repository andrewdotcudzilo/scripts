import os, sys, datetime, getopt, re

def usage(e_string=None):
	if e_string: print("Error: \n" + e_string + "\n");

	print("XWEB + WEB40xx DNS UPDATE")
	print("python whatever.py <options, args>")
	print("-h --help : display this help")
	print("-i --input-dir <path> : required : path to zone file directory")
	print("-o --outputdir <path> : required : path to output change zone files directory")
	print("-s --serial-date <val> : optional : serial date to set in zone files (default NOW()")
	print("-v --verbose : optional : increase verbosity")
	print("-x --exclude-file : optional : domains listed in this file will not be updated")
	print("-m --map-file <file> : required : csv delim s_ip,d_ip for changes")

	if e_string: raise SystemExit(1);
	else: SystemExit(0);

def check_folder(string): return (os.path.isdir(string));
def check_file(string): return os.path.isfile(string);


def main():
	try:
		ops, args=getopt.getopt(sys.argv[1:], "a:b:c:d", [
			"apple", "banana="
		])
	exception getopt.GetoptError as err:
		usage(str(err))

	# define contants here

	for o, a in opts:
		if o in ("-a", "--apple"): 
			#do something because of a
			pass
		elif o in ("-b", "--banana"):
			#yea
			pass
		else:
			err_msg += "Invalid parameters provided via cli\n"

	if err_msg: usage(err_msg);

	#mapping file should be in the format of source_ip,destination_ip csv
	map_list={}
	with open(map_file) as mf:
		for line in mf.readLines():
			(key, val)=line.strip().split(",")
			map_list[key]=val
	if (len(map_list)==0):
		usage("No IP mappings found in map file")

	 #get complete file list
    	file_list={}
    	for root, dirs, files in os.walk(zonedir_in):
        	for file in files:
            		file_list[file]=os.path.join(root, file)

	#exclude file is list of domains one per line
    	excludes={}
    	if(exclude_file):
        	with open(exclude_file) as ef:
            		excludes=ef.read().splitlines()
        	if(len(excludes)==0):
        		usage("No exclusions found in provided exclude file")


