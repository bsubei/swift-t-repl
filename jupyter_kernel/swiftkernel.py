from ipykernel.kernelbase import Kernel
import subprocess

class SwiftKernel(Kernel):
    implementation = 'Echo'
    implementation_version = '1.0'
    language = 'no-op'
    language_version = '0.1'
    language_info = {'mimetype': 'text/plain'}
    banner = "Echo kernel - as useful as a parrot"


    def kernel_startup():
        print subprocess.Popen("echo Hello World", shell=True, stdout=subprocess.PIPE).stdout.read()

    kernel_startup()

    # on kernel launch:
        # launch a turbine repl instance, and keep track of it using a pipe.
        # subprocess.Popen("echo Hello World", shell=True, stdout=subprocess.PIPE).stdout.read()


    def do_execute(self, code, silent, store_history=True, user_expressions=None,
                   allow_stdin=False):
        if not silent:

            # append extern statements to user's scripts

            # compile user's code in STC


            stream_content = {'name': 'stdout', 'text': code}
            self.send_response(self.iopub_socket, 'stream', stream_content)

        return {'status': 'ok',
                # The base class increments the execution count
                'execution_count': self.execution_count,
                'payload': [],
                'user_expressions': {},
               }

if __name__ == '__main__':
    from ipykernel.kernelapp import IPKernelApp
    IPKernelApp.launch_instance(kernel_class=SwiftKernel)
