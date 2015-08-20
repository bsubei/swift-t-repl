from ipykernel.kernelbase import Kernel
from subprocess import Popen, PIPE, STDOUT
import io
import signal
import time
import sys
import socket
import re
import string

class SwiftKernel(Kernel):
    implementation = 'Echo'
    implementation_version = '1.0'
    language = 'no-op'
    language_version = '0.1'
    language_info = {'mimetype': 'text/plain'}
    banner = "Swift/T kernel - Runs a Turbine instance and passes it user-entered Swift scripts."
    turbine_process = None
    sock = None
    globals_map = None
    import_modules = None

    # starts up the kernel by launching the repl turbine
    # TODO figure out how to pass number of processes to turbine command
    def kernel_startup():
        global turbine_process
        global sock

        # TODO initialize all globals here
        global import_modules
        import_modules = []

        try:

            # Create a server socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind(('localhost', 12345))
            sock.listen(1)

            turbine_process = Popen("turbine -n 4 ~/swift-t-repl/repl_leaf/repl_leaf.tic",
                                    stdout=sys.stdout, stderr=STDOUT, shell=True)
            # turbine_process = Popen("python ~/swift-t-repl/test-socket-client.py",
            #                         stdout=sys.stdout, stderr=STDOUT, shell=True)

        except:
            print("Could not start up turbine process or create socket")
            quit()

    kernel_startup()

    def do_execute(self, code, silent, store_history=True, user_expressions=None,
                   allow_stdin=False):

        global import_modules

        if not silent:

            # prepend previous import statements
            for module in import_modules:
                code = "import " + module + ";\n" + code

            # search for imports and append them to list of imports
            match_obj = re.search(r'\s*import\s+(\S+)\s*;', code)
            if match_obj:
                for obj in match_obj.groups():
                    # if it doesn't already exist, append it
                    if obj not in import_modules:
                        import_modules.append(obj)
                        # print("adding " + str(obj) + " to imports")

            print "sending code:\n" + code
            sys.stdout.flush()
            # open socket connection
            (conn, addr) = sock.accept()
            # send user code to turbine repl over socket
            conn.send(code)
            # receive from socket (output from repl)
            turbine_output = conn.recv(4096)
            # close connection
            conn.close()

            # TODO update globals_map from turbine_output

            # send response back to Jupyter client
            stream_content = {'name': 'stdout', 'text': turbine_output}
            self.send_response(self.iopub_socket, 'stream', stream_content)

        return {'status': 'ok',
                # The base class increments the execution count
                'execution_count': self.execution_count,
                'payload': [],
                'user_expressions': {},
               }

    # tells jupyter client whether code entered is complete (or should be continued)
    def do_is_complete(self, code):
        complete = self.braces_match(code)
        # TEMPORARY FIX: if open brace exists, it is incomplete until
        # final closing brace is entered.
        if complete:
            return {'status': 'complete'}
        else:
            return {'status': 'incomplete'}

    # given a string, return True if there are no braces or if braces
    # are matching (opening and closing). Return False otherwise.
    def braces_match(self, str):
        find_result = string.find(str, "{")
        counter = 0
        # no braces exist at all
        if find_result < 0:
            return True
        else:
            # go over every char
            for c in str:
                # increment/decrement counter upon seeing braces
                if c == '{':
                    counter += 1
                elif c == '}':
                    counter -= 1
            # unbalanced braces, input incomplete
            if counter != 0:
                return False
            # balanced braces, input complete
            else:
                return True


    # TODO not actually called by kernel!
    # called when kernel is about to shutdown
    def do_shutdown(self, restart=False):
        # turbine_process.terminate()
        # turbine_process.kill()

        print "shutting down!"
        # close the socket
        sock.close()
        # kill turbine process
        turbine_process.kill()
        # turbine_process.send_signal(signal.SIGKILL)


if __name__ == '__main__':
    from ipykernel.kernelapp import IPKernelApp
    IPKernelApp.launch_instance(kernel_class=SwiftKernel)
