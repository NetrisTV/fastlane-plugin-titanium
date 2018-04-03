describe Fastlane::Actions::TitaniumAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The titanium plugin is working!")

      Fastlane::Actions::TitaniumAction.run(nil)
    end
  end
end
