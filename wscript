import glob
import os
import platform
from waflib.TaskGen import extension, feature
from waflib.Task import Task

VERSION = '0.1'
APPNAME = 'catnip'

top = '.'


def options(opt):
    if platform.system() in ['Linux','Darwin']:
        opt.load('clang++')
    else:
        opt.load('msvc')


def configure(conf):
    if platform.system() in ['Linux','Darwin']:
        conf.load('clang++')
    else:
        conf.find_program('win_flex', path_list='win_flex_bison', exts='.exe')
        conf.find_program('win_bison', path_list='win_flex_bison', exts='.exe')
        conf.load('msvc')


class build_lex(Task):
    color = 'PINK'
    if platform.system() in ['Linux','Darwin']:
        run_str = 'lexx -o ${TGT} ${SRC}'
    else:
        run_str = '${WIN_FLEX} -o ${TGT} ${SRC}'


class build_yacc(Task):
    color = 'PINK'
    if platform.system() in ['Linux','Darwin']:
        run_str = 'bison -d -o ${TGT} ${SRC}'
    else:
        run_str = '${WIN_BISON} -d -o ${TGT} ${SRC}'


@extension('.l')
def build_flex_source(self, node):
    self.create_task('build_lex', node, node.change_ext('.cpp'))


@extension('.y')
def build_bison_source(self, node):
    self.create_task('build_yacc', node, node.change_ext('.cpp'))


def build(ctx):

    if platform.system() in ['Linux','Darwin']:
        if platform.system() == 'Darwin':
            platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_MACOSX', 'DEBUG']
        else:
            platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_LINUX', 'DEBUG']
        compile_flags = ['-std=c++17']
        linker_flags = []

        ctx(source=glob.glob('source/*.l'), target='clexx', before='cxx')
        ctx(source=glob.glob('source/*.y'), target='cyacc', before='cxx')

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
            use=['cyacc', 'clexx'])
    else:
        platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_WINDOWS']
        win_sdk_lib_path = '$(ProgramFiles)/Windows Kits/10/Lib/10.0.18362.0/um/x64/'
        winsdkinclude = '$(ProgramFiles)/Windows Kits/10/Include/10.0.18362.0/um/x64/'
        wsdkincludeshared = '$(ProgramFiles)/Windows Kits/10/Include/10.0.18362.0/shared'
        includes = ['source', 'includes', winsdkinclude, wsdkincludeshared]
        libs = ['user32', 'Comdlg32', 'gdi32', 'ole32', 'kernel32', 'winmm', 'ws2_32', 'SDL2']

        # RELEASE
        # compile_flags = ['/permissive-', '/arch:AVX', '/GL', '/WX', '/Ox', '/Ot', '/Oy', '/fp:fast', '/Qfast_transcendentals', '/Zi', '/EHsc', '/FS', '/D_SECURE_SCL 0']
        # linker_flags = ['/LTCG', '/RELEASE']

        # DEBUG
        compile_flags = ['/permissive-', '/arch:AVX', '/GL', '/WX', '/Od', '/DDEBUG', '/fp:fast', '/Qfast_transcendentals', '/Zi', '/Gs', '/EHsc', '/FS']
        linker_flags = ['/DEBUG']

        sdlpath = os.path.abspath('SDL')
        ctx(features='subst',
            source=ctx.root.find_resource(os.path.join(sdlpath, 'SDL2.dll')),
            target='SDL2.dll', is_copy=True, before='cxx')

        ctx(source=glob.glob('source/*.y'), target='cyacc', before='cxx')
        ctx(source=glob.glob('source/*.l'), target='clexx', before='cxx')

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
            use=['cyacc', 'clexx'])
