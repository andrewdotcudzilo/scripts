import os, sys, datetime, getopt

def usage():
    print("DNS ZONE FILE UPDATE SCRIPT - andrew.cudzilo@hostwaycorp.com")
    print("python poc.py <options,args> as follows")
    print("-h --help : display this help")
    print("-i --input-dir <path> : required :path to the zone file directory")
    print("-o --output-dir <path> : required: path to the output zone file directory for changes")
    print("-s --serial-date <val> : optional :the serial number/date to set updates to : default to NOW()")
    print("-v --verbose : optional : increased reporting")
    print("-x --exclude-file <file> : optional : domains listed in this file will not be updated")
    print("-m --map-file <file> : required : csv delim of src_ip,dst_ip translation/updates")

def check_folder(fol):
    if not fol: return false;
    if fol is None: return false;
    return ( os.path.isdir(fol))


def check_file(fil):
    if not fil: return false;
    if fil is None: return false;
    return os.path.isfile(fil)

def exclude(d, e):
    return d in e

def print_error(str):
    print("\n")
    print(str)
    raise SystemExit(2)


def check(v, i, o, s, x, m, f):
    write_output=False
    file_base=os.path.splitext(os.path.basename(f))[0]

    if(exclude(file_base,x)):
            print ("Excluding domain: "+file_base+" from dns updates.")
            return

    with open(str(i+f), "r") as thisFile:
        myfile=thisFile.read()

        for key in m:
            if key in myfile:
                write_output=True
                myfile=myfile.replace(key, m[key])

    if write_output:

        # figure out serial date updates between two envs




        of=open(str(o+f), "w")
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
    serialdate=datetime.datetime.today().strftime('%Y-%m-%d-%H-%M-%s')
    exclude=False
    excludefile=None
    mapfile='';
    zonedir_in=None
    zonedir_out=None
    debug=True
    bail=False
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

    maplist={}
    with open(mapfile) as f:
        for line in f:
            (key,val)=line.strip().split(',')
            maplist[key]=val

    for root, dirs, files in os.walk(zonedir_in):
        pass

    if(exclude):
        with open(excludefile) as f:
            excludes=f.read().splitlines()

    count_map=len(maplist)
    count_files=len(files)
    count_excludes=len(excludes)
    count=1


    if(verbose):
        print("Starting updates:")
        print("Number of IP mappings: "+str(count_map))
        print("Number of zone files considered: "+str(count_files))
        print("Number of excluded domains: "+str(count_excludes))

    for file in files:
        if(verbose):
            print("File "+str(count)+" of "+str(count_files))
            count +=1
        check(verbose, zonedir_in, zonedir_out, serialdate, excludes, maplist, file);

if __name__ == "__main__":
    main()
