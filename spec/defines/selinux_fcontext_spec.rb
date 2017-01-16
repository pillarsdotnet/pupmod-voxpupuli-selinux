require 'spec_helper'

describe 'selinux::fcontext' do
  let(:title) { 'myfile' }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'ordering' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            seltype: 'user_home_dir_t'
          }
        end
        it { is_expected.to contain_selinux__fcontext('myfile').that_requires('Anchor[selinux::module post]') }
        it { is_expected.to contain_selinux__fcontext('myfile').that_comes_before('Anchor[selinux::end]') }
      end

      context 'invalid pathname' do
        it { expect { is_expected.to compile }.to raise_error(%r{Must pass pathname to | expects a value for parameter 'pathname'}) }
      end

      context 'equal requires destination' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            equals: true
          }
        end
        it { expect { is_expected.to compile }.to raise_error(%r{is not an absolute path}) }
      end

      context 'invalid filemode with filetype false' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            filetype: false,
            filemode: 'X',
            seltype: 'user_home_dir_t'
          }
        end
        it { expect { is_expected.to compile }.to raise_error(%r{"filemode" must be one of: a,f,d,c,b,s,l,p - see "man semanage-fcontext"}) }
      end
      context 'invalid filetype' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            filetype: true,
            filemode: 'X',
            seltype: 'user_home_dir_t'
          }
        end
        it { expect { is_expected.to compile }.to raise_error(%r{"filemode" must be one of: a,f,d,c,b,s,l,p - see "man semanage-fcontext"}) }
      end
      context 'invalid multiple filetype' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            filetype: true,
            filemode: 'afdcbslp',
            seltype: 'user_home_dir_t'
          }
        end
        it { expect { is_expected.to compile }.to raise_error(%r{"filemode" must be one of: a,f,d,c,b,s,l,p - see "man semanage-fcontext"}) }
      end
      context 'equals and filetype' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            equals: true,
            filemode: 'a',
            seltype: 'user_home_dir_t',
            destination: '/tmp/file2'
          }
        end
        it { expect { is_expected.to compile }.to raise_error(%r{cannot set both "equals" and "seltype" as they are mutually exclusive}) }
      end
      context 'substituting fcontext' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            equals: true,
            destination: '/tmp/file2'
          }
        end
        it { is_expected.to contain_selinux_fcontext_equivalence('/tmp/file1').with(target: '/tmp/file2') }
        it { is_expected.to contain_exec('restorecond semanage::fcontext[/tmp/file1]').with(command: 'restorecon /tmp/file1') }
      end
      context 'set filemode and context' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            filetype: true,
            filemode: 'a',
            seltype: 'user_home_dir_t'
          }
        end
        it { is_expected.to contain_selinux_fcontext('/tmp/file1_a').with(pathspec: '/tmp/file1', seltype: 'user_home_dir_t', file_type: 'a') }
        it { is_expected.to contain_exec('restorecond semanage::fcontext[/tmp/file1]').with(command: 'restorecon /tmp/file1') }
      end

      context 'set context' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            seltype: 'user_home_dir_t'
          }
        end
        it { is_expected.to contain_selinux_fcontext('/tmp/file1_a').with(pathspec: '/tmp/file1', seltype: 'user_home_dir_t', file_type: 'a') }
        it { is_expected.to contain_exec('restorecond semanage::fcontext[/tmp/file1]').with(command: 'restorecon /tmp/file1') }
      end

      context 'with restorecon disabled' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            seltype: 'user_home_dir_t',
            restorecond: false
          }
        end
        it { is_expected.not_to contain_exec('restorecond semanage::fcontext[/tmp/file1]').with(command: %r{restorecon}) }
      end
      context 'with restorecon specific path' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            seltype: 'user_home_dir_t',
            restorecond_path: '/tmp/file1/different'
          }
        end
        it { is_expected.to contain_selinux_fcontext('/tmp/file1_a').with(pathspec: '/tmp/file1', seltype: 'user_home_dir_t', file_type: 'a') }
        it { is_expected.to contain_exec('restorecond semanage::fcontext[/tmp/file1]').with(command: 'restorecon /tmp/file1/different') }
      end
      context 'with restorecon recurse specific path' do
        let(:params) do
          {
            pathname: '/tmp/file1',
            seltype: 'user_home_dir_t',
            restorecond_path: '/tmp/file1/different',
            restorecond_recurse: true
          }
        end
        it { is_expected.to contain_selinux_fcontext('/tmp/file1_a').with(pathspec: '/tmp/file1', seltype: 'user_home_dir_t', file_type: 'a') }
        it { is_expected.to contain_exec('restorecond semanage::fcontext[/tmp/file1]').with(command: 'restorecon -R /tmp/file1/different') }
      end
      context 'with restorecon path with quotation' do
        let(:params) do
          {
            pathname: '/tmp/"$HOME"/"$PATH"/[^ \'\\\#\`]+(?:.*)',
            seltype: 'user_home_dir_t'
          }
        end
        it { is_expected.to contain_selinux_fcontext('/tmp/"$HOME"/"$PATH"/[^ \'\\\#\`]+(?:.*)_a').with(pathspec: '/tmp/"$HOME"/"$PATH"/[^ \'\\\#\`]+(?:.*)', seltype: 'user_home_dir_t', file_type: 'a') }
        it { is_expected.to contain_exec('restorecond semanage::fcontext[/tmp/"$HOME"/"$PATH"/[^ \'\\\#\`]+(?:.*)]').with(command: 'restorecon "/tmp/\\"\\$HOME\\"/\\"\\$PATH\\"/[^ \'\\\\\\\\#\\\\\`]+(?:.*)"') }
      end
    end
  end
end
