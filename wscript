import glob
import os
import platform

VERSION = '0.1'
APPNAME = 'catnip'

top = '.'


def options(opt):
    if platform.system() == 'Linux':
        opt.load('clang++')
    else:
        opt.load('msvc')


def configure(conf):
    if platform.system() == 'Linux':
        conf.load('clang++')
    else:
        conf.load('msvc')


def build(ctx):

    if platform.system() == 'Linux':
        platform_defines = ['_CRT_SECURE_NO_WARNINGS', 'CAT_LINUX', 'DEBUG']
        compile_flags = ['-std=c++17']
        linker_flags = []

        ctx.program(
            source=glob.glob('source/*.cpp'),
            cxxflags=compile_flags,
            ldflags=linker_flags,
            target='catnip',
            defines=platform_defines,
            includes=['source', 'includes'],
            libpath=[],
            lib=['SDL2'],
            use=[''])
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

        ctx.program(
            source=glob.glob('source/*.cpp'),
            cxxflags=compile_flags,
            ldflags=linker_flags,
            target='catnip',
            defines=platform_defines,
            includes=includes,
            libpath=[win_sdk_lib_path, os.path.abspath('SDL')],
            lib=libs,
            use=[''])

        sdlpath = os.path.abspath('SDL')
        ctx(features='subst',
            source=ctx.root.find_resource(os.path.join(sdlpath, 'SDL2.dll')),
            target='SDL2.dll', is_copy=True)
