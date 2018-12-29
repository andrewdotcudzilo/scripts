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
    if not fol:
        return false
    if fol is None:
        return false
    return (os.path.isdir(fol))


def check_file(fil):
    if not fil:
        return false
    if fil is None:
        return false
    return os.path.isfile(fil)

# checks if string d exists in array e


def exclude(d, e):
    return d in e


def print_error(str):
    print("\n")
    print(str)
    raise SystemExit(2)

# check and write output of regex-based search and replace
# f[filename with {.,.dns}]=fullpath


def check(v, i, o, s, x, m, f, fp, classic, odin):
    writeZoneFile = False
    writeArpaFile = False

    domain = os.path.splitext(os.path.basename(f))[0]
    full_path_out = str(o + "/" + fp)

    # ignore if in exclustion list
    if(exclude(domain, x)):
        print ("Excluding domain: " + domain + " from dns updates.")
        return

    # open the file, see if any src ip strings exist in string
    # if so, do hard regex search and substitute as needed
    with(open(fp)) as thisFile:
        myfile = thisFile.read()
        for key in m:

            # this will handle normal src to dst ip mapping
            if key in myfile:
                pattern = "\s" + key + "\s"
                if(re.search(pattern, myfile)):
                    if(classic):
                        myfile = re.sub(pattern, m[key], myfile)
                    elif(odin):
                        myfile = re.sub(pattern, m[key] + "\n", myfile)
                    writeZoneFile = True

            if(odin):
                src_arpa_list = key.split(".")
                src_arpa_list.reverse()
                src_arpa=".".join(src_arpa_list)

                if src_arpa in myfile:
                    dst_arpa_list = m[key].split(".")
                    dst_arpa_list.reverse()
                    dst_arpa = ".".join(dst_arpa_list)
                    print(src_arpa+" to "+dst_arpa)

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
    verbose = True
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
        with open(excludefile) as f:
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
        check(verbose, zonedir_in, zonedir_out, serialdate,
              excludes, maplist, file, file_list[file], classic, odin)

if __name__ == "__main__":
    main()
