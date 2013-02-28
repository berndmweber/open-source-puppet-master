require 'spec_helper_system'

describe 'run something remote' do
  let(:stack) do
    {
      :main => {
        :box => {
          :prefab => 'centos-58-x86_64',
        },
      },
    }
  end

  it 'must work' do
    run_on(:main, 'echo foo')
  end
end
