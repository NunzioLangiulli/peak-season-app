# Adds the "PeakSeasonLiveActivity" widget extension (the iPhone shopping-mode
# Live Activity) to Runner.xcodeproj and embeds it in the app.
#
# Normally this is two clicks in Xcode. Without a Mac, the GitHub workflow
# (.github/workflows/ios.yml) runs this script before `flutter build ios`.
# It does nothing if the target is already there, so it is also safe to run
# once on a Mac and commit the result:
#
#   gem install xcodeproj
#   ruby ios/scripts/add_live_activity_target.rb
require 'xcodeproj'

NAME = 'PeakSeasonLiveActivity'
BUNDLE_ID = 'it.peakseason.peakSeason.LiveActivity'
DEPLOYMENT_TARGET = '16.1' # first iOS with Live Activities

project_path = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

if project.targets.any? { |t| t.name == NAME }
  puts "#{NAME} is already in the project"
  exit 0
end

app = project.targets.find { |t| t.name == 'Runner' } or abort('Runner target not found')
ext = project.new_target(:app_extension, NAME, :ios, DEPLOYMENT_TARGET, nil, :swift)

# Source files, in ios/PeakSeasonLiveActivity/
group = project.main_group.new_group(NAME, NAME)
widget = group.new_reference('PeakSeasonLiveActivity.swift')
shared = group.new_reference('ShoppingActivityAttributes.swift')
assets = group.new_reference('Assets.xcassets')
group.new_reference('Info.plist')
ext.add_file_references([widget, shared])
ext.add_resources([assets])

# The app compiles the shared attributes and the bridge to Dart.
runner_group = project.main_group['Runner'] or abort('Runner group not found')
bridge = runner_group.new_reference('LiveActivityBridge.swift')
app.add_file_references([shared, bridge])

# Same configurations as the app (Debug, Release, Profile), on top of Flutter's
# xcconfig files, so the extension gets the app's version and build number.
xcconfigs = project.files.select { |f| f.path.to_s.end_with?('.xcconfig') }
debug_xcconfig = xcconfigs.find { |f| f.path == 'Flutter/Debug.xcconfig' }
release_xcconfig = xcconfigs.find { |f| f.path == 'Flutter/Release.xcconfig' }
app.build_configurations.map(&:name).each do |name|
  next if ext.build_configurations.any? { |c| c.name == name }
  ext.add_build_configuration(name, name == 'Debug' ? :debug : :release)
end
ext.build_configurations.each do |config|
  config.base_configuration_reference = config.name == 'Debug' ? debug_xcconfig : release_xcconfig
  s = config.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  s['INFOPLIST_FILE'] = "#{NAME}/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SWIFT_VERSION'] = '5.0'
  s['SKIP_INSTALL'] = 'YES'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['ASSETCATALOG_COMPILER_APPICON_NAME'] = ''
end

# Build the extension before the app and copy it into Runner.app/PlugIns.
app.add_dependency(ext)
embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
build_file = embed.add_file_reference(ext.product_reference, true)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Flutter's "Thin Binary" script must run after the embed phase, otherwise
# Xcode reports a dependency cycle.
thin = app.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
if thin
  app.build_phases.delete(embed)
  app.build_phases.insert(app.build_phases.index(thin), embed)
end

project.save
puts "Added #{NAME} (#{BUNDLE_ID}) to the project"
