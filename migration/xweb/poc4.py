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
def exclude(d, e): return d in e;

def return_arpa_ip(mylist):
    l=mylist[:]
    l.reverse()
    return(".".join(l))


def print_error(str):
    print("\n")
    print(str)
    raise SystemExit(2)

# check and write output of regex-based search and replace
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

# checks the file for an instance of source->dest arpa ip to update
def arpacheck(v, o, x, m, f, fp):
    writeOutput=False
    path_out=str(o+"/"+fp)
    file_string=""

    # these are the general odin linked arpa files, where whole subnets are defined
    # therefor we need to iterate then line be unfortunetly for our checks

    with(open(fp)) as thisFile:
        myfile=thisFile.readlines()
    
    for line in myfile:
        for key in m:
            excludeLine=False
            #we need to translate the source ip to arpa ip
            source_ip=key
            dest_ip=m[key]

            source_ip_list=key.split(".")
            arpa_source_ip=return_arpa_ip(source_ip_list)

            if(re.search("^"+arpa_source_ip+".IN-ADDR.ARPA.", line)):
                #check excludes
                for ex in x:
                    if ex in line: excludeLine=True

                if not excludeLine:
                    dest_ip_list=m[key].split(".")
                    arpa_dest_ip=return_arpa_ip(dest_ip_list)
                    line=re.sub("^"+arpa_source_ip+".IN-ADDR.ARPA.", arpa_dest_ip+".IN-ADDR.ARPA.", line)
                    writeOutput=True
                    file_string+=line
        #done for, add back line

        if writeOutput: 
            #changes detected; need to update arpa reference of path of file
            path_out=re.sub(str(source_ip_list[0]), str(dest_ip_list[0]), path_out)
            path_out=re.sub(str(source_ip_list[1]), str(dest_ip_list[1]), path_out)
            writeOut(file_string, path_out)

# this intends to rebuild the pathing for the 1.2.3.IN-ADDR.ARPA files that build
# the structure of the reverse zones
def arpa_rebuild(v,o,m,f,fp):
    writeOutput=False
    path_out=str(o+"/"+fp)
    updateNeeded=False

    with(open(fp)) as thisFile:
        myfile=thisFile.read()


    update_src_key=False
    update_dst_key=False
    for key in m:

        source_ip_list=key.split(".")
        del source_ip_list[-1]
        arpa_source_ip=return_arpa_ip(source_ip_list)
        

        if(re.search("^"+arpa_source_ip, myfile)):

            dest_ip_list=m[key].split(".")
            del dest_ip_list[-1]
            arpa_dest_ip=return_arpa_ip(dest_ip_list)

            myfile=re.sub("^"+arpa_source_ip+".IN-ADDR.ARPA.", arpa_dest_ip+".IN-ADDR.ARPA.", myfile)

            update_src_key=source_ip_list
            update_dst_key=dest_ip_list
            updateNeeded=True


    file_string=""
    if(updateNeeded):
    #need to go line by line her to change the exact line
        for line in myfile.splitlines():
            if "reverse_zones" in line:
                line=re.sub(str(update_src_key[0]), str(update_dst_key[0]), line)
                line=re.sub(str(update_src_key[1]), str(update_dst_key[1]), line)
            file_string+=line+"\n"


    if(updateNeeded):
        path_out=re.sub(arpa_source_ip+".IN-ADDR.ARPA.", arpa_dest_ip+".IN-ADDR.ARPA", path_out)
        writeOut(file_string, path_out)
        #check this???



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

<<<<<<< HEAD
            # this will handle normal src to dst ip mapping
            if key in myfile:
                pattern = "\s" + key + "\s"
                if(re.search(pattern, myfile)):
                    if(classic):
                        myfile = re.sub(pattern, m[key], myfile)
                    elif(odin):
                        myfile = re.sub(pattern, m[key] + "\n", myfile)
                    writeZoneFile = True

			# handles the reverse dns records....in progress
            if(odin):
                src_arpa_list = key.split(".")
				src_arpa_list_rev = src_arpa_list

                src_arpa_list_rev.reverse()
                src_arpa=".".join(src_arpa_list_rev)

                if src_arpa in myfile:
                    dst_arpa_list = m[key].split(".")
                    dst_arpa_list.reverse()
                    dst_arpa = ".".join(dst_arpa_list)
                    print(src_arpa+" to "+dst_arpa+" from file "+fp)

    # we had a match above, so we're writing output, update the serial based
    # on env
    if writeZoneFile:
        if(classic):
            if(re.search("\d{10}\s+;\s+serial", myfile)):
                myfile = re.sub("\d{10}\s+;\s+serial", s + " serial", myfile)
        elif(odin):
            if(re.search("\(\d{10}\s{1}", myfile)):
                match = re.search("\(\d{10}\s{1}", myfile).group(0)
                serial = int(match[1:])
                serial += 1
                myfile = re.sub(
                    "\(\d{10}\s{1}", "(" + str(serial) + " ", myfile)

    if writeZoneFile:
        if(v):
            print("file: " + f + " domain: " + f + " updated")

        if not os.path.exists(os.path.dirname(full_path_out)):
            try:
                os.makedirs(os.path.dirname(full_path_out))
            except OSError as exc:
                if exc.errno != errno.EEXIST:
                    raise

        with open(full_path_out, "w") as o:
            o.write(myfile)
=======
def writeOut(s, path_out, v=False):
    if not os.path.exists(os.path.dirname(path_out)):
        try:
            os.makedirs(os.path.dirname(path_out))
        except OSError as e:
            if x.errno != errno.EEXIST:
                raise
    with(open(path_out,"w")) as o:
        o.write(s)
>>>>>>> b477136fbec09350dbea58621b801ba6a3b527fa


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
<<<<<<< HEAD
    verbose = False 
=======
    verbose = False
>>>>>>> b477136fbec09350dbea58621b801ba6a3b527fa
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
        check(verbose, zonedir_out, serialdate,
              excludes, maplist, file, file_list[file], classic, odin)
        if(odin): 
            arpacheck(verbose, zonedir_out, excludes, maplist, file, file_list[file])
            arpa_rebuild(verbose, zonedir_out, maplist, file, file_list[file])

if __name__ == "__main__":
    main()
