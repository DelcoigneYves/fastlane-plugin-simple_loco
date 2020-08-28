describe Fastlane::Actions::SimpleLocoAction do
  describe '#run' do
    it 'runs' do
      Fastlane::Actions::SimpleLocoAction.run(conf_file_path: 'fastlane/Loco.Android.json')
    end
  end
end
