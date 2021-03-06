require 'spec_helper'

describe "jasmine-headless-webkit" do
  let(:report) { 'spec/report.txt' }

  before do
    FileUtils.rm_f report
  end

  after do
    FileUtils.rm_f report
  end

  describe 'success' do
    it "should succeed with error code 0" do
      system %{bin/jasmine-headless-webkit -j spec/jasmine/success/success.yml --report #{report}}
      $?.exitstatus.should == 0

      report.should be_a_report_containing(1, 0, false)
    end
  end


  describe 'success but with js error' do
    it "should succeed with error code 0" do
      system %{bin/jasmine-headless-webkit -j spec/jasmine/success_with_error/success_with_error.yml --report #{report}}
      $?.exitstatus.should == 1

      report.should be_a_report_containing(1, 0, false)
    end
  end

  describe 'failure' do
    it "should fail with an error code of 1" do
      system %{bin/jasmine-headless-webkit -j spec/jasmine/failure/failure.yml --report #{report}}
      $?.exitstatus.should == 1

      report.should be_a_report_containing(1, 1, false)
    end
  end

  describe 'with console.log' do
    it "should succeed, but has a console.log so an error code of 2" do
      system %{bin/jasmine-headless-webkit -j spec/jasmine/console_log/console_log.yml --report #{report}}
      $?.exitstatus.should == 2

      report.should be_a_report_containing(1, 0, true)
    end
  end

  describe 'with coffeescript error' do
    it "should fail" do
      system %{bin/jasmine-headless-webkit -j spec/jasmine/coffeescript_error/coffeescript_error.yml --report #{report}}
      $?.exitstatus.should == 1

      File.exist?(report).should be_false
    end
  end

  describe 'with filtered run' do
    context "don't run a full run, just the filtered run" do
      it "should succeed and run both" do
        system %{bin/jasmine-headless-webkit -j spec/jasmine/filtered_success/filtered_success.yml --no-full-run --report #{report} ./spec/jasmine/filtered_success/success_one_spec.js}
        $?.exitstatus.should == 0

        report.should be_a_report_containing(1, 0, false)
      end
    end

    context "do both runs" do
      it "should fail and not run the second" do
        system %{bin/jasmine-headless-webkit -j spec/jasmine/filtered_failure/filtered_failure.yml --report #{report} ./spec/jasmine/filtered_failure/failure_spec.js}
        $?.exitstatus.should == 1

        report.should be_a_report_containing(1, 1, false)
      end

      it "should succeed and run both" do
        system %{bin/jasmine-headless-webkit -j spec/jasmine/filtered_success/filtered_success.yml --report #{report} ./spec/jasmine/filtered_success/success_one_spec.js}
        $?.exitstatus.should == 0

        report.should be_a_report_containing(2, 0, false)
      end
    end
  end
end

