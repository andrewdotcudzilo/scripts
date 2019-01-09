import os, sys, datetime, getopt, re

def usage(error_string=None):
    if error_string: print("Error:\n"+error_string+"\n");
    print("DNS ZONE FILE UPDATE SCRIPT - andrew.cudzilo@hostwaycorp.com")
    print("python poc.py <options,args> as follows")
    print("-h --help : display this help")
    print("-i --input-dir <path> : required : path to the zone file directory")
    print(
        "-o --output-dir <path> : required:  path to the output zone file directory for changes")
    print(
        "-s --serial-date <val> : optional : the serial number/date to set updates to : default to NOW()")
    print("-v --verbose : optional : increased reporting")
    print(
        "-x --exclude-file <file> : optional : domains listed in this file will not be updated")
    print("-m --map-file <file> : required : csv delim of src_ip,dst_ip translation/updates")
    if error_string:
        raise SystemExit(1)
    else:
        raise SystemExit(0)


def check_folder(string): return (os.path.isdir(string));
def check_file(string): return os.path.isfile(string);
def write_output_file(fs, fp, v=False):
    if not os.path.exists(os.path.dirname(fp)):
        try:
            os.makedirs(os.path.dirname(fp))
        except OSError as err:
            if err.errno != errno.EEXIST:
                raise
    with(open(fp,"w")) as o:
        o.write(fs)
#end write_output_file

def update_zone(orig, new, string, v=False):
#    return re.sub(orig, " "+new+" ", string)
	return
def in_exclude(ex, domain, v=False):
    if domain in ex: return True;
    return False;

def main():

    print("in main")
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hi:o:s:vx:m:", [
            "help", "input-directory=", "output-directory=", "verbose", "exclude-file=", "map-file="
        ])
    except getopt.GetoptError as err:
        usage(str(err))

    exclude_file=None
    zonedir_in=None
    zonedir_out=None
    verbose=False
    map_file=None
    err_msg=""

    for o, a in opts:
        if o in ("-h", "--help"): usage();
        elif o in ("-i", "--input-directory"):
            if(check_folder(a)): zonedir_in=a;
            else: err_msg += "Zone files input directory not found\n";
        elif o in ("-o", "--output-directory"): zonedir_out=a;
        elif o in ("-x", "--exclude-file"):
            if(check_file(a)): exclude_file=a;
            else: err_msg+="Exclude file not found/provided\n";
        elif o in ("-m", "--map-file"):
            if(check_file(a)): map_file=a;
            else: err_msg+="Mapping file not found/provided\n";
        elif o in ("-v", "--verbose"): verbose=True;
        else:
            err_msg += "Invalid parameters provided via command line\n"
            assert False, "Unhandled option"

    if not opts: usage();
    if map_file is None: err_msg+="Mapping file not provided.\n";
    
    map_list={}
    with open(map_file) as mf:
        for line in mf.readlines():
            (key,val)=mf.strip().split(",")
            map_list[key]=val

    file_list={}
    for root, dirs, files in os.walk(zonedir_in):
        for file in files:
            file_list[file]=os.path.join(root, file)
    

    excludes={}
    if exclude_file:
        with open(exclude_file) as ef:
            excludes=ef.read.splitlines()

    c_map_list=len(map_list)
    c_file_list=len(file_list)
    c_excludes=len(excludes)

    if(c_map_list==0): usage("No IP Mappings found in map file provided.")

            

if __name__ == "__main__":
    main()

