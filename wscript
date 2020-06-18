import glob
import os
import platform
from waflib.TaskGen import extension, feature, task_gen
from waflib.Task import Task
from waflib import Build

VERSION = '0.1'
APPNAME = 'catnip'

top = '.'


def options(opt):
    if platform.system() in ['Linux', 'Darwin']:
        opt.load('clang++')
    else:
        # Prefers msvc, but could also use conf.load('clang++') instead
        opt.load('msvc')


def configure(conf):
    if platform.system() in ['Linux', 'Darwin']:
        # Prefers msvc, but could also use conf.load('clang++') instead
        conf.load('clang++')
        # TODO: This might break, will need to fix if it does
        conf.find_program('bison', path_list='/usr/bin')
        conf.find_program('flex', path_list='/usr/bin')
    else:
        # Prefers msvc, but could also use conf.load('clang++') instead
        conf.load('msvc')
        conf.find_program('bison', path_list='buildtools', exts='.exe')
        conf.find_program('flex', path_list='buildtools', exts='.exe')


class run_bison(Task):
    color = 'PINK'
    run_str = ['${BISON} -d -o  ${TGT} ${SRC}']


class run_flex(Task):
    color = 'PINK'
    run_str = ['${FLEX} -o ${TGT} ${SRC}']


@extension('.l')
def generate_grammar(self, node):
    self.create_task('run_flex', node,
                     node.parent.find_or_declare(node.name + '.cpp'))


@extension('.y')
def generate_grammar(self, node):
    self.create_task('run_bison', node,
                     node.parent.find_or_declare(node.name + '.cpp'))


def build(bld):

    if platform.system() in ['Linux', 'Darwin']:
        if platform.system() == 'Darwin':
            platform_defines = ['_CRT_SECURE_NO_WARNINGS',
                                'CAT_MACOSX', 'DEBUG']
        else:
            platform_defines = ['_CRT_SECURE_NO_WARNINGS',
                                'CAT_LINUX', 'DEBUG']
        compile_flags = ['-std=c++17']
        linker_flags = []

        bld.post_mode = Build.POST_LAZY

        flexsource = glob.glob('grammar/*.l')
        bisonsource = glob.glob('grammar/*.y')

        sdlpath = os.path.abspath('SDL')
        bld(features='subst',
            source=bld.root.find_resource(os.path.join(sdlpath, 'SDL2.dll')),
            target='SDL2.dll', is_copy=True, before='cxx')

        bld(source=flexsource,
            target='grammarscanner')
        bld.add_group()

        bld(source=bisonsource,
            target='grammarparser')
        bld.add_group()

        bld.program(
            features='find_new_files',
            source=glob.glob('source/*.cpp'),
            cxxflags=compile_flags,
            ldflags=linker_flags,
            target='catnip',
            defines=platform_defines,
            includes=['source', 'includes', 'SDL'],
            libpath=[],
            lib=['SDL2'],
            use=['grammarscanner', 'grammarparser'])
    else:
        platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_WINDOWS']
        slib = '%ProgramFiles%Windows Kits/10/Lib/'
        sinc = '%ProgramFiles%Windows Kits/10/Include/'
        win_sdk_lib_path = os.path.expandvars(slib+'10.0.19041.0/um/x64/')
        winsdkinclude = os.path.expandvars(sinc+'10.0.19041.0/um/x64/')
        wsdkincludeshared = os.path.expandvars(sinc+'10.0.19041.0/shared')
        includes = ['source', 'includes', 'buildtools',
                    winsdkinclude, wsdkincludeshared]
        libs = ['user32', 'Comdlg32', 'gdi32', 'ole32',
                'kernel32', 'winmm', 'ws2_32', 'SDL2']

        # RELEASE - vcc
        compile_flags = ['/permissive-', '/std:c++17', '/arch:AVX',
                         '/GL', '/WX', '/Ox', '/Ot', '/Oy', '/fp:fast',
                         '/Qfast_transcendentals', '/Zi', '/EHsc',
                         '/FS', '/D_SECURE_SCL 0',
                         '/D_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS']
        linker_flags = ['/LTCG', '/RELEASE']

        # DEBUG - vcc
        # compile_flags = ['/permissive-', '/std:c++17', '/arch:AVX',
        #                  '/GL', '/WX', '/Od', '/DDEBUG', '/fp:fast',
        #                  '/Qfast_transcendentals', '/Zi', '/Gs',
        #                  '/EHsc', '/FS']
        # linker_flags = ['/DEBUG']

        # RELEASE - clang
        # compile_flags = ['-std=c++17', '-g',
        #                  '-D_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS',
        #                  '-DDEBUG', '-D_SECURE_SCL=0']
        # linker_flags = [''] # '-stdlib=libc++'

        bld.post_mode = Build.POST_LAZY

        flexsource = glob.glob('grammar\\*.l')
        bisonsource = glob.glob('grammar\\*.y')

        sdlpath = os.path.abspath('SDL')
        bld(features='subst',
            source=bld.root.find_resource(os.path.join(sdlpath, 'SDL2.dll')),
            target='SDL2.dll', is_copy=True, before='cxx')

        bld(source=flexsource,
            target='grammarscanner')
        bld.add_group()

        bld(source=bisonsource,
            target='grammarparser')
        bld.add_group()

        bld.program(
            features='find_new_files',
            source=glob.glob('source/*.cpp'),
            cxxflags=compile_flags,
            ldflags=linker_flags,
            target='catnip',
            defines=platform_defines,
            includes=includes,
            libpath=[win_sdk_lib_path, os.path.abspath('SDL')],
            lib=libs,
            use=['grammarscanner', 'grammarparser'])


from waflib.TaskGen import feature, before
from waflib import Utils
@feature('find_new_files')
@before('process_source')
def list_the_source_files(self):
    gensrc = self.path.ant_glob('build/release/grammar/*.cpp', quiet=True)
    self.source = Utils.to_list(self.source) + gensrc
