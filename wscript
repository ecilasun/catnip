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
        conf.load('msvc') #clang++


def build(ctx):

    if platform.system() in ['Linux', 'Darwin']:
        if platform.system() == 'Darwin':
            platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_MACOSX', 'DEBUG']
        else:
            platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_LINUX', 'DEBUG']
        compile_flags = ['-std=c++17']
        linker_flags = []

        ctx.program(
            source=glob.glob('source/*.cpp'),
            cxxflags=compile_flags,
            ldflags=linker_flags,
            target='catnip',
            defines=platform_defines,
            includes=['source', 'includes', 'SDL'],
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
        compile_flags = ['/permissive-', '/std:c++17', '/arch:AVX', '/GL', '/WX', '/Ox', '/Ot', '/Oy', '/fp:fast', '/Qfast_transcendentals', '/Zi', '/EHsc', '/FS', '/D_SECURE_SCL 0', '/D_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS']
        linker_flags = ['/LTCG', '/RELEASE']

        # DEBUG - vcc
        # compile_flags = ['/permissive-', '/std:c++17', '/arch:AVX', '/GL', '/WX', '/Od', '/DDEBUG', '/fp:fast', '/Qfast_transcendentals', '/Zi', '/Gs', '/EHsc', '/FS']
        # linker_flags = ['/DEBUG']

        # RELEASE - clang
        # compile_flags = ['-std=c++17', '-g', '-D_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS', '-DDEBUG', '-D_SECURE_SCL=0']
        # linker_flags = [''] # '-stdlib=libc++'

        sdlpath = os.path.abspath('SDL')
        ctx(features='subst',
            source=ctx.root.find_resource(os.path.join(sdlpath, 'SDL2.dll')),
            target='SDL2.dll', is_copy=True, before='cxx')

        ctx.program(
            source=glob.glob('source/*.cpp'),
            cxxflags=compile_flags,
            ldflags=linker_flags,
            target='catnip',
            defines=platform_defines,
            includes=includes,
            libpath=[win_sdk_lib_path, os.path.abspath('SDL')],
            lib=libs,
            use=['parsercode'])
