#!/usr/local/python

import re
import sys
import os
import os.path


new_thread = re.compile('^"(.*)"')

def process_stack_trace(fname):
    if not os.path.isdir('threads'):
        os.mkdir('threads')
    tname = fname.split('/')[-1]    
    output = open('threads/dummy_' + tname, 'w')
    


    with open(fname) as f:
        for l in f.readlines():
            m = new_thread.match(l)
            if m:
                thread_name = m.group(1).replace('/', '')
                output.close()
                if not os.path.exists('threads/' + thread_name) or not os.path.isdir('threads/' + thread_name):
                    os.mkdir('threads/' + thread_name)
                output = open('threads/' + thread_name + '/' + tname, 'a')
            output.write(l)
    output.close()

if __name__ == '__main__':
    if os.path.isfile(sys.argv[1]):
        process_stack_trace(sys.argv[1])
    elif os.path.isdir(sys.argv[1]):
        for thread_file in os.listdir(sys.argv[1]):
            process_stack_trace(sys.argv[1] + '/' + thread_file)
