import os, sys, datetime, getopt, re

def usage():
    print("DNS ZONE FILE UPDATE SCRIPT - andrew.cudzilo@hostwaycorp.com")
    print("python poc.py <options,args> as follows")
    print("-h --help : display this help")
    print("-i --input-dir <path> : required : path to the zone file directory")
    print("-o --output-dir <path> : required:  path to the output zone file directory for changes")
    print("-s --serial-date <val> : optional : the serial number/date to set updates to : default to NOW()")
    print("-v --verbose : optional : increased reporting")
    print("-x --exclude-file <file> : optional : domains listed in this file will not be updated")
    print("-m --map-file <file> : required : csv delim of src_ip,dst_ip translation/updates")
    print(" -- note -- only traverses single directory level --")

def check_folder(fol):
    if not fol: return false;
    if fol is None: return false;
    return ( os.path.isdir(fol))

def check_file(fil):
    if not fil: return false;
    if fil is None: return false;
    return os.path.isfile(fil)

# checks if string d exists in array e
def exclude(d, e):
    return d in e

def print_error(str):
    print("\n")
    print(str)
    raise SystemExit(2)

# check and write output of regex-based search and replace
def check(v, i, o, s, x, m, f):
    write_output=False
    file_base=os.path.splitext(os.path.basename(f))[0]

    #ignore if in exclustion list
    if(exclude(file_base,x)):
            print ("Excluding domain: "+file_base+" from dns updates.");  return;

    #open file, weak check for string, then strong check
    # so 168.144.1.1 does not match 168.144.1.11, etc
    with open(str(i+"/"+f), "r") as thisFile:
        myfile=thisFile.read()
        for key in m:
            if key in myfile:
                if re.search("\s"+key+"\s", myfile):
                    myfile=re.sub("\s"+key, " "+m[key], myfile)
                    write_output=True

    if write_output:
        #classic serial date is simple date+xx
        if(re.search("\d{10}\s+;\s+serial", myfile)):
            myfile=re.sub("\d{10}\s+;\s+serial", s+" serial", myfile)
        #oncloud seems to use separate serial, so we just increase the searial # by 1
        elif(re.search("\(\d{10}\s{1}", myfile)):
            match=re.search("\(\d{10}\s{1}", myfile).group(0)
            serial=int(match[1:])
            serial+=1
            myfile=re.sub("\(\d{10}\s{1}", "("+str(serial)+" ", myfile)
        
        if(v): print("file: "+f+" domain: "+file_base+" updated")
        
        of=open(str(o+"/"+f), "w")
        of.write(myfile)
        of.close

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hi:o:s:vx:m:", [
            "help", "input-dir=", "output-dir=", "serial-date=", "verbose", "exclude-file=", "map-file="
        ])
    except getopt.GetoptError as err:
        usage()
        print_error(str(err))

    verbose=True
    serialdate=datetime.datetime.today().strftime('%Y%m%d')+"01"
    exclude=False
    excludefile=None
    mapfile='';
    zonedir_in=None
    zonedir_out=None
    errmsg='';

    for o,a in opts:
        if o in ("-h", "--help"):
            usage()
            raise SystemExit
        elif o in ("-i", "--input-dir"):
            if(check_folder(a)): zonedir_in=a;
            else: errmsg+="Zone input dir not found\n";
        elif o in ("-o", "--output-dir"):
            if(check_folder(a)): zonedir_out=a;
            else: errmsg+="Zone output dir not found\n";
        elif o in ("-s", "--serial-date"): serialdate=a;
        elif o in ("-v", "--verbose"): verbose=True;
        elif o in ("-x", "--exclude-file"):
            if(check_file(a)): exclude=True; excludefile=a;
            else: errmsg+="Exclusion file does not exist or not provided with flag\n";
        elif o in ("-m", "--map-file"):
            if(check_file(a)): mapfile=a;
            else: errmsg+="Map file not found/provided\n";
        else:
            errmsg+="Something is wrong with your option paramters"
            assert False, "unhandled option"

    if(not zonedir_in): errmsg+="Zone input dir not provided\n";
    if(not zonedir_out): errmsg+="Zone output dir not provided\n";
    if(errmsg): usage(); print_error(errmsg);

    #map list of src-str to dst-srt
    maplist={}
    with open(mapfile) as f:
        for line in f:
            (key,val)=line.strip().split(',')
            maplist[key]=val

    #file list to update based on limiters
    filelist=[]
    ext=[ ".dns", "." ]
    for filename in os.listdir(zonedir_in):
        if os.path.isfile(os.path.join(zonedir_in, filename)):
            if(filename.endswith(tuple(ext))):
                filelist.append(filename)
   
    #read/build exclusion list
    excludes=[]
    if(exclude):
        with open(excludefile) as f:
            excludes=f.read().splitlines()

    # counts for status
    count_map=len(maplist)
    count_files=len(filelist)
    count_excludes=len(excludes)
    count=1


    if(verbose):
        print("Starting updates:")
        print("Number of IP mappings: "+str(count_map))
        print("Number of zone files considered: "+str(count_files))
        print("Number of excluded domains: "+str(count_excludes))

    for file in filelist:
        if(verbose):
            print("File "+str(count)+" of "+str(count_files))
            count +=1
        check(verbose, zonedir_in, zonedir_out, serialdate, excludes, maplist, file);

if __name__ == "__main__":
    main()
