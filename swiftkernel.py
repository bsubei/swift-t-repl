from ipykernel.kernelbase import Kernel
from subprocess import Popen, PIPE, STDOUT
import io
import signal
import time
import sys
import socket


class SwiftKernel(Kernel):
    implementation = 'Echo'
    implementation_version = '1.0'
    language = 'no-op'
    language_version = '0.1'
    language_info = {'mimetype': 'text/plain'}
    banner = "Swift/T kernel - Runs a Turbine instance and passes it user-entered Swift scripts."
    turbine_process = None
    sock = None

    # starts up the kernel by launching the repl turbine
    # TODO figure out how to pass number of processes to turbine command
    def kernel_startup():
        global turbine_process
        global sock

        try:
            # turbine_process = Popen("turbine -n 4 ~/swift-t-repl/repl_leaf/repl_leaf.tic",
            #                         stdout=sys.stdout, stderr=STDOUT, shell=True)
            # Create a server socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind(('localhost', 12345))
            sock.listen(1)

            turbine_process = Popen("python ~/swift-t-repl/test-socket-client.py",
                                    stdout=sys.stdout, stderr=STDOUT, shell=True)

        except:
            print("Could not start up turbine process or create socket")
            quit()

    kernel_startup()

    def do_execute(self, code, silent, store_history=True, user_expressions=None,
                   allow_stdin=False):
        if not silent:

            # append extern statements to user's scripts

            # compile user's code in STC

            # open socket connection
            (conn, addr) = sock.accept()
            # send user code to turbine repl over socket
            conn.send(code)
            # receive from socket (output from repl)
            turbine_output = conn.recv(4096)
            # close connection
            conn.close()

            # send response back to Jupyter client
            stream_content = {'name': 'stdout', 'text': turbine_output}
            self.send_response(self.iopub_socket, 'stream', stream_content)

        return {'status': 'ok',
                # The base class increments the execution count
                'execution_count': self.execution_count,
                'payload': [],
                'user_expressions': {},
               }

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
