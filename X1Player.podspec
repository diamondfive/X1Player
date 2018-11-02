
Pod::Spec.new do |s|
  s.name         = 'X1Player'
  s.version      = '1.0'
  s.summary      = 'A good iOS media player made by yanzhang'
  s.description  = <<-DESC
                  #基于ffmpeg封装的视频播放 支持直播 录播视频的播放,支持常用的播放界面控制，类似于ijkplayer 优点是体积更小,使用快捷
                   DESC

  s.homepage     = 'https://github.com/diamondfive'
  s.screenshots  = 'https://github.com/diamondfive/X1Player/blob/develop/showtime.png?raw=true'
  s.license      = { :type => 'MIT', :file => 'LICENSE' } 
  s.author       = { 'yanzhang' => 'fyz333501@163.com' }
 

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
    s.platform     = :ios, "8.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "8.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/diamondfive/X1Player.git", :tag => "1.0" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "X1PlayerSDK", "X1Player/X1PlayerSDK/**/*.{h,m,mm}"
  #s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
    s.resources = "X1Player/X1PlayerSDK/**/*.{bundle,a}"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = "SomeFramework"
    s.frameworks = "CoreTelephony", "OpenAL","VideoToolbox","GLKit"

  # s.library   = "iconv"
    s.libraries = "bz2","iconv","z"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

    s.requires_arc = true
    s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }

  # s.xcconfig = {'ENABLE_BITCODE' => 'NO'}
  # s.dependency "JSONKit", "~> 1.4"

end

