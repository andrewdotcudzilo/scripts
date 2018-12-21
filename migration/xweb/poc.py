import os, getopt

def usage():
    print("DNS ZONE FILE UPDATE SCRIPT - andrew.cudzilo@hostwaycorp.com")
    print("python poc.py <options,args> as follows")
    print("-h --help : display this help")
    print("-i --input-dir <path> : path to the zone file directory")
    print("-o --output-dir <path> : path to the output zone file directory for changes")
    print("-s --serial-date <val> : the serial number/date to set updates to")
    print("-v --verbose : increased reporting")
    print("-x --exclude-file <file> : domains listed in this file will not be updated")
    print("-m --map-file <file> : csv delim of src_ip,dst_ip translation/updates")

def check_folder(fol):
    if(!os.path.isdir(fol)):
        print("directory: "+fol+" does not exist")

def check_file(fil):
    if(!os.path.exists(fil)):
        print("file: "+fil+" does not exist")

def exclude(d, e):
    return d in e


def check(v, i, o, s, x, m, f):
    write_output=False
    file_base=os.path.splitext(os.path.basename(f))[0]

    if(exclude(file_base,e) :
            print ("Excluding domain: "+file_base+" from dns updates.")
            return

    with open(str(i+f), "r") as thisFile:
        myfile=thisFile.read()

        for key in m:
            if key in myfile:
                write_output=false
                myfile=myfile.replace(key, m[key])

    if write_output:
        of=open(str(o+f), "w")
        of.write(myfile)
        of.close

def main():
    try:
        opts, args = getop.getopt(sys.argv[1:], "hi:o:s:vx:m:", ["help"])
    except getout.GetoptError as err:
        print str(err)
        usage()
        raise SystemExit(2)

    verbose=True
    zonedir_in="./customer_pz/"
    zonedir_out="./customer_pz_out/"
    serialdate=datetime.datetime.today().strftime('%Y-%m-%d-%H-%M-%s')
    exclude=False

    for o,a in opts:
        if o in ("-h", "--help"):
            usage()
            raise SystemExit
        elif o in ("-i", "--input-dir"):
            zonedir_in=a
            if(!check_folder(zonedir_in)):
                raise SystemExit(2)
        elif o in ("-o", "--output-dir"):
            zonedir_out=a
            if(!check_folder(zonedir_out)):
                raise SystemExit(2)
        elif o in ("-s", "--serial-date"):
            serialdate=a
        elif o in ("-v", "--verbose"):
            verbose=True
        elif o in ("-x", "--exclude-file"):
            exclude=True
            excludefile=a
        elif o in ("-m", "--map-file"):
            mapfile=a
            if(!check_file(mapfile)):
                raise SystemExit(2)
        else:
            assert False, "unhandled option"


        maplist={}
        with open(mapfile, "r") as f:
            for line in f:
                (key,val)=line.strip().split(',')
                maplist[key]=val

        for root, dirs, files in os.walk(zonedir_in):
            pass


        if(exclude):
            with open(excludefile) as f:
                excludes=f.read.splitlines()

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
