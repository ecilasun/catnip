import glob
import os
import platform
from waflib.TaskGen import extension, feature
from waflib.Task import Task

VERSION = '0.1'
APPNAME = 'catnip'

top = '.'


def options(opt):
    if platform.system() in ['Linux', 'Darwin']:
        opt.load('clang++')
    else:
        opt.load('msvc') #clang++


def configure(conf):
    if platform.system() in ['Linux', 'Darwin']:
        conf.load('clang++')
    else:
        conf.find_program('win_flex', path_list='win_flex_bison', exts='.exe')
        conf.find_program('win_bison', path_list='win_flex_bison', exts='.exe')
        conf.find_program('win_re2c', path_list='win_re2c', exts='.exe')
        conf.load('msvc') #clang++


class build_yacc_then_re2c(Task):
    color = 'PINK'
    if platform.system() in ['Linux', 'Darwin']:
        run_str = ['bison ${SRC} -o ${SRC}.re', 're2c ${SRC}.re -o ${TGT}']
    else:
        run_str = ['${WIN_BISON} ${SRC} -o ${SRC}.re', '${WIN_RE2C} ${SRC}.re -o ${TGT}']


@extension('.y')
def build_bison_source(self, node):
    self.create_task('build_yacc_then_re2c', node, node.change_ext('.cpp'))


def build(ctx):

    if platform.system() in ['Linux', 'Darwin']:
        if platform.system() == 'Darwin':
            platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_MACOSX', 'DEBUG']
        else:
            platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_LINUX', 'DEBUG']
        compile_flags = ['-std=c++17']
        linker_flags = []

        ctx(source=glob.glob('source/*.y'), name='parsercode', before='cxx')

        generatedsource = glob.glob('build/release/source/*.cpp')

        ctx.program(
            source=glob.glob('source/*.cpp') + generatedsource,
            cxxflags=compile_flags,
            ldflags=linker_flags,
            target='catnip',
            defines=platform_defines,
            includes=['source', 'includes'],
            libpath=[],
            lib=['SDL2'],
            use=['parsercode'])
    else:
        platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_WINDOWS']
        win_sdk_lib_path = '$(ProgramFiles)/Windows Kits/10/Lib/10.0.18362.0/um/x64/'
        winsdkinclude = '$(ProgramFiles)/Windows Kits/10/Include/10.0.18362.0/um/x64/'
        wsdkincludeshared = '$(ProgramFiles)/Windows Kits/10/Include/10.0.18362.0/shared'
        includes = ['source', 'includes', winsdkinclude, wsdkincludeshared]
        libs = ['user32', 'Comdlg32', 'gdi32', 'ole32', 'kernel32', 'winmm', 'ws2_32', 'SDL2']

        # RELEASE - vcc
        # compile_flags = ['/permissive-', '/std:c++17', '/arch:AVX', '/GL', '/WX', '/Ox', '/Ot', '/Oy', '/fp:fast', '/Qfast_transcendentals', '/Zi', '/EHsc', '/FS', '/D_SECURE_SCL 0']
        # linker_flags = ['/LTCG', '/RELEASE']

        # DEBUG - vcc
        compile_flags = ['/permissive-', '/std:c++17', '/arch:AVX', '/GL', '/WX', '/Od', '/DDEBUG', '/fp:fast', '/Qfast_transcendentals', '/Zi', '/Gs', '/EHsc', '/FS']
        linker_flags = ['/DEBUG']

        # RELEASE - clang
        # compile_flags = ['-std=c++17', '-g', '-D_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS', '-DDEBUG', '-D_SECURE_SCL=0']
        # linker_flags = [''] # '-stdlib=libc++'

        sdlpath = os.path.abspath('SDL')
        ctx(features='subst',
            source=ctx.root.find_resource(os.path.join(sdlpath, 'SDL2.dll')),
            target='SDL2.dll', is_copy=True, before='cxx')

        ctx(source=glob.glob('source/*.y'), target='parsercode', name='parsercode', before='cxx')

        generatedsource = glob.glob('build/release/source/*.cpp')

        ctx.program(
            source=glob.glob('source/*.cpp') + generatedsource,
            cxxflags=compile_flags,
            ldflags=linker_flags,
            target='catnip',
            defines=platform_defines,
            includes=includes,
            libpath=[win_sdk_lib_path, os.path.abspath('SDL')],
            lib=libs,
            use=['parsercode'])
