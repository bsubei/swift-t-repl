from ipykernel.kernelbase import Kernel
from subprocess import Popen, PIPE, STDOUT
import io
import signal


class SwiftKernel(Kernel):
    implementation = 'Echo'
    implementation_version = '1.0'
    language = 'no-op'
    language_version = '0.1'
    language_info = {'mimetype': 'text/plain'}
    banner = "Swift/T kernel - Runs a Turbine instance and passes it user-entered Swift scripts."
    turbine_process = None

    # starts up the kernel by launching the repl turbine and opening a pipe to it.
    # TODO figure out how to pass number of processes to turbine command
    def kernel_startup():
        global turbine_process
        try:
            turbine_process = Popen("turbine -n 4 ~/swift-t-repl/repl_leaf/repl_leaf.tic",
                                    stdin=PIPE, stdout=PIPE, stderr=STDOUT, shell=True)
        except:
            print("Popen failed")
            quit()

    kernel_startup()

    def do_execute(self, code, silent, store_history=True, user_expressions=None,
                   allow_stdin=False):
        if not silent:

            # append extern statements to user's scripts

            # compile user's code in STC

            # taken from: http://stackoverflow.com/a/28019908/341505
            # write to turbine process (repl tcl is listening to stdin)
            with turbine_process.stdin:
                turbine_process.stdin.write(code)
                turbine_process.stdin.flush()

            # read back from turbine process
            sout = io.open(turbine_process.stdout.fileno(), 'rb', closefd=False)
            buf = ""
            while True:
                buf = sout.read1(1024)
                if len(buf) == 0:
                    break
                print buf,
            turbine_output = buf

            stream_content = {'name': 'stdout', 'text': turbine_output}
            self.send_response(self.iopub_socket, 'stream', stream_content)

        return {'status': 'ok',
                # The base class increments the execution count
                'execution_count': self.execution_count,
                'payload': [],
                'user_expressions': {},
               }

    # called when kernel is about to shutdown
    def do_shutdown(self, restart=False):
        # turbine_process.terminate()
        # turbine_process.kill()
        turbine_process.send_signal(signal.SIGINT)

if __name__ == '__main__':
    from ipykernel.kernelapp import IPKernelApp
    IPKernelApp.launch_instance(kernel_class=SwiftKernel)
