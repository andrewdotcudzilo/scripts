import os
import sys
import datetime
import getopt
import re


def usage():
    print("DNS ZONE FILE UPDATE SCRIPT - andrew.cudzilo@hostwaycorp.com")
    print("python poc.py <options,args> as follows")
    print("-h --help : display this help")
    print("-e --env <string> : requred : {classic, odin}")
    print("-i --input-dir <path> : required : path to the zone file directory")
    print(
        "-o --output-dir <path> : required:  path to the output zone file directory for changes")
    print(
        "-s --serial-date <val> : optional : the serial number/date to set updates to : default to NOW()")
    print("-v --verbose : optional : increased reporting")
    print(
        "-x --exclude-file <file> : optional : domains listed in this file will not be updated")
    print(
        "-m --map-file <file> : required : csv delim of src_ip,dst_ip translation/updates")
    print(" -- note -- only traverses single directory level --")


def check_folder(fol):
    if not fol: return false
    if fol is None: return false
    return (os.path.isdir(fol))


def check_file(fil):
    if not fil: return false
    if fil is None: return false
    return os.path.isfile(fil)

# checks if string d exists in array e
def exclude(d, e): return d in e


def print_error(str):
    print("\n")
    print(str)
    raise SystemExit(2)

# check and write output of regex-based search and replace
# f[filename with {.,.dns}]=fullpath
def check(v, o, s, x, m, f, fp, classic, odin):
    writeOutput = False

    domain = os.path.splitext(os.path.basename(f))[0]
    path_out = str(o + "/" + fp)

    # ignore if in exclustion list
    if(exclude(domain, x)):
        print ("Excluding domain: " + domain + " from dns updates.")
        return

    # open the file, see if any src ip strings exist in string
    # if so, do hard regex search and substitute as needed
    with(open(fp)) as thisFile:
        myfile = thisFile.read()


        # for each ip in the src->dst mapping
        for key in m:
            if key in myfile:
                #handle a case where source IP has matched
                pattern = "\s" + key + "\s"
                if(re.search(pattern, myfile)): # a more specific match so we don't get partials
                    myfile=normalUpdate(pattern, m[key], myfile, classic, odin) #normal update
                    myfile=serialUpdate(s, myfile, classic, odin) #serial update
                    writeOutput=True
                    
    if(writeOutput): writeOut(myfile, path_out)
    #end output
#end function
            
def arpacheck(v, o, x, m, f, fp):
    writeOutput=False
    path_out=str(o+"/"+fp)
    myoutput=""

    #excludes are tricky, need to match the host line not the arpa to make sure we're not updating an exclude
    with(open(fp)) as thisFile:
        myfile = thisFile.readlines();

    for line in myfile:

        for key in m:

            source_ip=key
            dest_ip=m[key]

            source_ip_list=key.split(".")
            tmp_source_ip_list=source_ip_list[:] #copy
            tmp_source_ip_list.reverse()
            arpa_source_ip = ".".join(tmp_source_ip_list)

            dest_ip_list=dest_ip.split(".")
            tmp_dest_ip_list=dest_ip_list[:] #copy
            tmp_dest_ip_list.reverse()
            arpa_dest_ip = ".".join(tmp_dest_ip_list)

            updateLine=False
            if(re.search("^"+arpa_source_ip+".IN-ADDR.ARPA.", line)):
                if(v): print("we have an arpa match on "+arpa_source_ip)
                updateLine=True

                for exclude in x:
                    if exclude in line: 
                        updateLine=False
                        print("Excluding arpa line "+line+" because of exclude "+exclude)


                if(updateLine):
                    line=re.sub("^"+arpa_source_ip+".IN-ADDR.ARPA.", arpa_dest_ip+".IN-ADDR.ARPA.", line)
                    print("new line = "+line)
                    writeOutput=True
        
        myoutput+=line
        #done for loop line
    #now we need output update(new file)

    if(writeOutput):
        path_out=re.sub(str(source_ip_list[0]), str(dest_ip_list[0]), path_out)
        path_out=re.sub(str(source_ip_list[1]), str(dest_ip_list[1]), path_out)
        writeOut(myoutput, path_out)
# end arpacheck

def arpa_rebuild(v,o,m,f,fp):
    writeOutput=False
    path_out=str(o+"/"+fp)
    changeMade=False
    myoutput=""

    with(open(fp)) as thisFile:
        myfile=thisFile.read()

    for key in m:

        source_ip=key
        dest_ip=m[key]

        source_ip_list=key.split(".")
        del source_ip_list[-1]
        tmp_source_ip_list=source_ip_list[:] # copy
        tmp_source_ip_list.reverse()
        arp_source_ip=".".join(tmp_source_ip_list)

        dest_ip_list=dest_ip.split(".")
        del dest_ip_list[-1]
        tmp_dest_ip_list=dest_ip_list[:] # copy
        tmp_dest_ip_list.reverse()
        arp_dest_ip=".".join(tmp_dest_ip_list)


        if(re.search("^"+arp_source_ip, myfile)):
            myfile=re.sub("^"+arp_source_ip+".IN-ADDR.ARPA.", arp_dest_ip+".IN-ADDR.ARPA.", myfile)
            changeMade=True

    mynewoutput=""
    if(changeMade):
        print("in changemade")
        for line in myfile.splitlines():
            if "reverse_zones" in line:
                print("found the reverse lines")
                line=re.sub(str(source_ip_list[0]), str(dest_ip_list[0]), line)
                line=re.sub(str(source_ip_list[1]), str(dest_ip_list[1]), line)
            mynewoutput+=line+"\n"    

    if(changeMade):
        path_out=re.sub(arp_source_ip+".IN-ADDR.ARPA.", arp_dest_ip+".IN-ADDR.ARPA", path_out)
        writeOut(mynewoutput, path_out)



def normalUpdate(source, target, s, classic, odin):
    if(classic): return re.sub(source, " "+target+" ", s)
    elif(odin): return re.sub(source, " "+target+" \n", s)
    else: return False

def serialUpdate(serial, s, classic, odin):
    if(classic): return re.sub("\d{10}\s+;\s+serial", searial + " serial", s)
    elif(odin):
        return s;
#        if(re.search("\(\d{10}\s{1}", d)):
#                match = re.search("\(\d{10}\s{1}", myfile).group(0)
#                serial = int(match[1:])
#                serial += 1
#                return(re.sub("\(\d{10}\s{1}", "(" + str(serial) + " ", s)
#        else: 
#            return 0;

def writeOut(s, path_out, v=False):
    if not os.path.exists(os.path.dirname(path_out)):
        try:
            os.makedirs(os.path.dirname(path_out))
        except OSError as e:
            if x.errno != errno.EEXIST:
                raise
    with(open(path_out,"w")) as o:
        o.write(s)


def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "he:i:o:s:vx:m:", [
            "help", "env=", "input-dir=", "output-dir=", "serial-date=", "verbose", "exclude-file=", "map-file="
        ])
    except getopt.GetoptError as err:
        usage()
        print_error(str(err))

    classic = False
    odin = False
    exclude = False
    exclude_file = None
    zonedir_in = None
    zonedir_out = None
    verbose = False
    serialdate = datetime.datetime.today().strftime('%Y%m%d') + "01"
    map_file = None
    mapfile = ''
    errmsg = ''

    for o, a in opts:
        if o in ("-h", "--help"):
            usage()
            raise SystemExit
        elif o in ("-i", "--input-dir"):
            if(check_folder(a)):
                zonedir_in = a
            else:
                errmsg += "Zone input dir not found\n"
        elif o in ("-o", "--output-dir"):
            zonedir_out = a
        elif o in ("-s", "--serial-date"):
            serialdate = a
        elif o in ("-v", "--verbose"):
            verbose = True
        elif o in ("-x", "--exclude-file"):
            if(check_file(a)):
                exclude = True
                exclude_file = a
            else:
                errmsg += "Exclusion file does not exist or not provided with flag\n"
        elif o in ("-m", "--map-file"):
            if(check_file(a)):
                map_file = a
            else:
                errmsg += "Map file not found/provided\n"
        elif o in ("-e", "--env"):
            if(a == "classic"):
                classic = True
            elif(a == "odin"):
                odin = True
            else:
                errmsg += "Environmentment flag not valid\n"
        else:
            errmsg += "Something is wrong with your option paramters"
            assert False, "unhandled option"

    if(not zonedir_in):
        errmsg += "Zone input dir not provided\n"
    if(not zonedir_out):
        errmsg += "Zone output dir not provided\n"
    if(errmsg):
        usage()
        print_error(errmsg)

    # map list of src-str to dst-srt
    maplist = {}
    with open(map_file) as f:
        for line in f:
            (key, val) = line.strip().split(',')
            maplist[key] = val

    # get full file list with pathing
    file_list = {}
    for root, dirs, files in os.walk(zonedir_in):
        for name in files:
            file_list[name] = os.path.join(root, name)

    # read/build exclusion list
    excludes = []
    if(exclude):
        with open(exclude_file) as f:
            excludes = f.read().splitlines()

    # counts for status
    count_map = len(maplist)
    count_files = len(file_list)
    count_excludes = len(excludes)
    count = 1

    if(verbose):
        print("Starting updates:")
        print("Number of IP mappings: " + str(count_map))
        print("Number of zone files considered: " + str(count_files))
        print("Number of excluded domains: " + str(count_excludes))

    for file in file_list:
        if(verbose):
            print("File " + str(count) + " of " + str(count_files))
            count += 1
#        check(verbose, zonedir_out, serialdate,
#              excludes, maplist, file, file_list[file], classic, odin)
        if(odin): 
 #           arpacheck(verbose, zonedir_out, excludes, maplist, file, file_list[file])
            arpa_rebuild(verbose, zonedir_out, maplist, file, file_list[file])

if __name__ == "__main__":
    main()
