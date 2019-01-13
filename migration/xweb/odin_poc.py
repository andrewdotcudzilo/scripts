import os, sys, datetime, getopt, re

def usage(error_string=None):
    if error_string: print("Error:\n"+error_string+"\n");
    print("DNS ZONE FILE UPDATE SCRIPT - andrew.cudzilo@hostwaycorp.com")
    print("python poc.py <options,args> as follows")
    print("-h --help : display this help")
    print("-i --input-dir <path> : required : path to the zone file directory")
    print(
        "-o --output-dir <path> : required:  path to the output zone file directory for changes")
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
    return re.sub(orig, " "+new+" \n", s)

def in_exclude(ex, domain, v=False):
    if domain in ex: return True;
    return False;

def process_file(o_dir, ex, maplist, f, fp, v=False):
    write_output=False
    domain=os.path.splitext(os.path.basename(f)[0])
    file_out = str(o_dir+"/"+fp)

    if(in_exclude(ex, domain, v)):
        if(v): 
            print (" "+domain+" skipped because of excludsion...");
        return

    wite(open(fp)) as zf:
        myfile = zf.read()

    for key in maplist:
        if key in myfile:
            pattern = "\s"+key+"\s"
            if(re.search(pattern, myfile)):
                myfile=update_zone(key, maplist[key], myfile)
                #do nothing for serial right now
                write_output=True

    if(write_output): 
        write_output_file(myfile, file_out, v)
        
def return_apra_ip(list):
    copy = list[:]
    copy.reverse()
    return(copy)


    

def check_arpa_file(o_dir, ex, maplist, f, fp):
    write_output=False
    file_out=(o_dir+"/"+fp)
    file_string=""

    with(open(fp)) as thisFile:
        myfile=thisFile.read()

    for line in myfile:
        for key in maplist:
            exclude_this_line=False:
            
            source_ip = key
            destination_ip = maplist[key]
        
            source_ip_list = key.split(",")
            arpa_source_ip = return_arpa_ip(source_ip_list)

            if(re.search("^"+arpa_source_list+".IN-ADDR.ARPA.", line)):
                for x in ex:
                    if ex in line: exclude_this_line=True

                if not exclude_this_line:
                    destination_ip_list=maplist[key].split(".")
                    arpa_destination_ip = return_arpa_ip(destination_ip_list)
                    line = re.sub("^"+arpa_source_ip+".IN-ADDR.ARPA.", 
                            arpa_destination_ip+".IN-ADDR.ARPA.", line)
                    write_output=True
                    file_string+=line

        if exclude_this_linst:
            file_string+=line

    if write_output:
        file_out = re.sub(str(source_ip_list[0]), str(destination_ip_list[0]), file_out)
        file_out = re.sub(str(source_ip_list[1]), str)destination_ip_list[1]), file_out)
        write_file_output(file_string, file_out)

def apra_structure_rebuild(o_dir, maplist, f, fp, v=False):
    write_output=False
    file_out = str(o_dir+"/"+fp)
    update_file_needed = False

    with(open(fp)) as thisFile:
        myfile=thisFile.read()

    update_src_key=False
    update_dst_key=False

    for key in maplist:
    
        source_ip_list=key.split(".")
        del source_ip_list[-1]
        arpa_source_ip = return_arpa_ip(source_ip_list)
        if(re.search("^"+arpa_source_ip+".IN-ADDR.ARPA.", myfile):

            destination_ip_list=maplist[key].split(".")
            del destination_ip_list[-1]
            apra_destination_ip = return_arpa_ip(destination_ip_list)

            myfile = re.sub("^"+arpa_source-list+".IN-ADDR.ARPA.",
                        arpa_destination_ip+".IN-ADDR.ARPA.", myfile)

            update_src_key = source_ip_list
            update_dst_key = destination_ip_list
            update_file_needed=True

    file_string=""
    if update_file_needed:
        for line in myfile.splitlines():
            if "reverse_zones" in line:
                line=re.sub(str(update_src_key[0]), str(update_dst_key[0]))
                line=re.sub(str(update_src_key[1]), str(update_dst_key[1]))
            file_string+=line+"\n"

    if(update_file_needed):
        file_out = re.sub(arpa_source_ip+".IN-ADDR.ARPA.", 
                    arpa_destination_ip+".IN-ADDR.ARPA.", file_out)

        write_output(file_string, file_out)



def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hi:o:vx:m:", [
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
    if err_msg: usage(err_msg);
    
    map_list={}
    with open(map_file) as mf:
        for line in mf.readlines():
            (key, val)=line.strip().split(",")
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
    count=1

    if(verbose):
        print("Starting updates...")
        print("Number of IP mappings:  "+str(c_map_list))
        print("Number of excluded domains: "+ str(c_excludes))

    for file in file_list:

    if(verbose):
        sys.stound.write("\r File: "+str(count)+" of "+str(c_file_list))
        sys.stdout.flush()
        count+=1
        process_file(zonedir_out, excludes, map_list, file, file_list[file], verbose)
            

    if(c_map_list==0): usage("No IP Mappings found in map file provided.")

            

if __name__ == "__main__":
    main()

