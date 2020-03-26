import glob
import os
import shutil
from waflib import Options, Task, Context, Utils, Errors, Node
from waflib.TaskGen import extension, before_method, feature
from waflib.Task import Task

VERSION = '0.1'
APPNAME = 'catnip'

top = '.'

def options(opt):
    # opt.load('clang++')
    # opt.load('msvc', funs='no_autodetect')
    opt.load('msvc')
    opt.load('msvs') # To generate Visual Studio projects when needed

def configure(conf):
    # conf.find_program('copybin', path_list='copybin', exts='.exe')
    # conf.load('clang++')
    # conf.env.MSVC_VERSIONS = ['msvc 16.5', 'msvc 15.9']
    # conf.env.MSVC_TARGETS = ['x64']
    conf.load('msvc')

def build(ctx):

    platform_defines = ['_CRT_SECURE_NO_WARNINGS']
    win_sdk_lib_path = '$(ProgramFiles)/Windows Kits/10/Lib/10.0.18362.0/um/x64/'
    win_sdk_include_path = '$(ProgramFiles)/Windows Kits/10/Include/10.0.18362.0/um/x64/'
    win_sdk_include_path_shared = '$(ProgramFiles)/Windows Kits/10/Include/10.0.18362.0/shared'

    # RELEASE
    # compile_flags = ['/permissive-', '/arch:AVX', '/GL', '/WX', '/Ox', '/Ot', '/Oy', '/fp:fast', '/Qfast_transcendentals', '/Zi', '/EHsc', '/FS', '/D_SECURE_SCL 0']
    # linker_flags = ['/LTCG', '/RELEASE']

    # DEBUG
    compile_flags = ['/permissive-', '/arch:AVX', '/GL', '/WX', '/Od', '/DDEBUG', '/fp:fast', '/Qfast_transcendentals', '/Zi', '/Gs', '/EHsc', '/FS']
    linker_flags = ['/DEBUG']

    # compile_flags = ['-std=c++17']
    # linker_flags = []

    ctx.program(
        source = glob.glob('source/*.cpp'),
        cxxflags = compile_flags, # + ['/Fdcatnip'],
        ldflags = linker_flags,
        target = 'catnip',
        defines = platform_defines,
        includes = ['source', 'includes', win_sdk_include_path, win_sdk_include_path_shared],
        libpath = [win_sdk_lib_path, os.path.abspath('libclang'), os.path.abspath('SDL')],
        lib = ['user32', 'Comdlg32', 'gdi32', 'ole32', 'kernel32', 'winmm', 'ws2_32', 'SDL2'],
        use = [''])

    sdlpath = os.path.abspath('SDL')
    ctx(features='subst', source=ctx.root.find_resource(os.path.join(sdlpath, 'SDL2.dll')), target='SDL2.dll', is_copy=True)
