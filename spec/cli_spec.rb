require 'tbm'

include TBM

describe CommandLineInterface do

	let( :config ) { double( TBM::Config ) }
	subject { CommandLineInterface.new config }

	before do
		TBM::ConfigParser.stub( :parse ) { config }
		config.stub( :valid? ) { config_valid }
		config.stub( :errors ) { config_errors }
		stub_messages
	end

	context "without valid config" do
		let(:config_valid) { false }
		let(:config_errors) { ["Invalid Config"] }
		it "should print config errors" do
			CommandLineInterface.parse_and_run
			@messages.should include_match(/Cannot parse config/)
			@messages.should include_match(/Invalid Config/)
		end
	end

	context "with no parameters" do
		let(:config_valid) { true }

		before do
			ARGV.clear
			config.stub(:each_target).and_yield( 'alpha' ).and_yield( 'beta' )
		end

		it "should print syntax and targets" do
			CommandLineInterface.parse_and_run
			@messages.should include_match( /SYNTAX/ )
			@messages.should include_match( /alpha/ )
			@messages.should include_match( /beta/ )
		end
	end

	context "with a single parameter" do
		let(:config_valid) { true }

		before do
			ARGV.clear.push( 'target-name' )
			config.stub(:get_target).with('target-name') { target }
		end

		context "matching a config target" do
			let(:target) { double Target }
			let(:thost) { 'target-host.example.com' }
			let(:tuser) { 'username' }
			let(:machine) { double( Machine ) }

			before do
				target.stub(:host) { thost }
				target.stub(:username) { tuser }
			end

			it "should start Tunnel Boring Machine" do
				Machine.stub(:new) { machine }
				machine.should_receive(:bore)
				CommandLineInterface.parse_and_run
			end
		end

		context "not matching a config target" do
			let(:target) { nil }

			before do
				config.stub(:each_target).and_yield( 'another-target' )
			end

			it "should say 'Cannot find target'" do
				CommandLineInterface.parse_and_run
				@messages.should include_match( /Cannot find target/ )
			end

			it "should print target list" do
				CommandLineInterface.parse_and_run
				@messages.should include_match( /another-target/ )
			end
		end
	end

	context "with multiple parameters" do
		let(:config_valid) { true }

		before do
			ARGV.clear.push( 'alpha', 'beta' )
			config.stub(:get_target).with('alpha') { alpha }
			config.stub(:get_target).with('beta') { beta }
		end

		context "matching configured targets with same host and user" do
			let(:alpha) { Target.new( 'alpha', 'host', 'username' ) }
			let(:beta) { Target.new( 'beta', 'host', 'username' ) }
			let(:machine) { double( Machine ) }

			it "should start boring machine" do
				Machine.stub(:new) { machine }
				machine.should_receive(:bore)
				CommandLineInterface.parse_and_run
			end
		end

		context "matching configured targets with different hosts" do
			let(:alpha) { double Target }
			let(:beta) { double Target }

			before do
				alpha.stub(:host) { 'host1' }
				alpha.stub(:username) { 'username' }
				beta.stub(:host) { 'host2' }
				beta.stub(:username) { 'username' }
			end

			it "should say 'Can't combine targets'" do
				CommandLineInterface.parse_and_run
				@messages.should include_match(/Can't combine targets/)
			end
		end

		context "matching configured targets with different usernames" do
			let(:alpha) { double Target }
			let(:beta) { double Target }

			before do
				alpha.stub(:host) { 'host' }
				alpha.stub(:username) { 'username1' }
				beta.stub(:host) { 'host' }
				beta.stub(:username) { 'username2' }
			end

			it "should say 'Can't combine targets'" do
				CommandLineInterface.parse_and_run
				@messages.should include_match(/Can't combine targets/)
			end
		end

		context "not all matching configured targets" do
			let(:alpha) { nil }
			let(:beta) { nil }

			before do
				config.stub(:each_target).and_yield( 'gamma' ).and_yield( 'delta' )
			end

			it "should say 'Cannot find target'" do
				CommandLineInterface.parse_and_run
				@messages.should include_match(/Cannot find target/)
			end

			it "should print target list" do
				CommandLineInterface.parse_and_run
				@messages.should include_match( /gamma/ )
				@messages.should include_match( /delta/ )
			end
		end
	end


end