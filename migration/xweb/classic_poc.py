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
    return re.sub(orig, " "+new+" ", string)
def update_serial(serial, string, v=False):
    return re.sub("\d{10}\s+;\s+serial", serial + " serial", string)
def in_exclude(ex, domain, v=False):
    if domain in ex: return True;
    return False;

def process_file(o_dir, ser, ex, maplist, f, fp, v=False):
    write_output=False
    domain=os.path.splitext(os.path.basename(f))[0]
    file_out = str(o_dir+"/"+fp)

    if(in_exclude(ex, domain, v)): return;

    with(open(fp)) as zf:
        myfile=zf.read()

    for key in maplist:
        if key in myfile: #partial match
            #source ip from map is in zone file so we do stuff
            pat="\s"+key+"\s"
            if(re.search(pat, myfile)): #exact match
                myfile=update_zone(pat, maplist[key], myfile, v)
                myfile=update_serial(ser, myfile, v)
                write_output=True

    if(write_output):
        if(v):
            print(" "+domain+" will be updated")
        write_output_file(myfile, file_out, v)
#end process file:

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hi:o:s:vx:m:", [
            "help", "input-directory=", "output-directory=", "serial-date=", "verbose", "exclude-file=", "map-file="
        ])
    except getopt.GetoptError as err:
        usage(str(err))

    exclude_file=None
    zonedir_in=None
    zonedir_out=None
    verbose=False
    serialdate =  datetime.datetime.today().strftime('%Y%m%d') + "01"
    map_file=None
    err_msg=""

    for o, a in opts:
        if o in ("-h", "--help"): usage();
        elif o in ("-i", "--input-directory"):
            if(check_folder(a)): zonedir_in=a;
            else: err_msg += "Zone files input directory not found\n";
        elif o in ("-o", "--output-directory"): zonedir_out=a;
        elif o in ("-s", "--serial-date"): serialdate=a;
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

    if map_file is None: err_msg+="Mapping file not provide d.\n"
    
    if err_msg: usage(err_msg);

    #end opts, read files in

    #map file in format of:
    #x.x.x.x,y.y.y.y where x is source ip and y is translated ip
    map_list={}
    with open(map_file) as mf:
        for line in mf.readlines():
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

    #counts for verbose
    c_map=len(map_list)
    c_files=len(file_list)
    c_excludes=len(excludes)
    count=1

    if(verbose):
        print("Starting updates:")
        print("Number of IP mappings: " + str(c_map))
        print("Number of zone files considered: " + str(c_files))
        print("Number of excluded domains: " + str(c_excludes))

    for file in file_list:
        if verbose:
            sys.stdout.write("\r File:  "+str(count)+" of "+str(c_files))
            sys.stdout.flush()
            count+=1
        process_file(zonedir_out, serialdate, excludes, map_list, file, file_list[file], verbose)

if __name__ == "__main__":
    main()
