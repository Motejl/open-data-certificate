# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Question do
  let(:question){ FactoryGirl.create(:question) }

  context "when creating" do
    it "is invalid without #text" do
      question.text = nil
      question.should have(1).error_on :text
    end
    it "#mandatory? == false by default" do
      question.mandatory?.should be_false
    end
    it "converts #pick to string" do
      question.pick.should == "none"
      question.pick = :one
      question.pick.should == "one"
      question.pick = nil
      question.pick.should == nil
    end
    it "#renderer == 'default' when #display_type = nil" do
      question.display_type = nil
      question.renderer.should == :default
    end
    it "has #api_id with 36 characters by default" do
      question.api_id.length.should == 36
    end
    it "#part_of_group? and #solo? are aware of question groups" do
      question.question_group = FactoryGirl.create(:question_group)
      question.solo?.should be_false
      question.part_of_group?.should be_true

      question.question_group = nil
      question.solo?.should be_true
      question.part_of_group?.should be_false
    end
    it "protects #api_id" do
      saved_attrs = question.attributes
      if defined? ActiveModel::MassAssignmentSecurity::Error
        expect { question.update_attributes(:api_id => "NEW") }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
      else
        question.attributes = {:api_id => "NEW"} # Rails doesn't return false, but this will be checked in the comparison to saved_attrs
      end
      question.attributes.should == saved_attrs
    end
    it "protects #created_at" do
      saved_attrs = question.attributes
      if defined? ActiveModel::MassAssignmentSecurity::Error
        expect { question.update_attributes(:created_at => 3.days.ago) }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
      else
        question.attributes = {:created_at => 3.days.ago} # Rails doesn't return false, but this will be checked in the comparison to saved_attrs
      end
      question.attributes.should == saved_attrs
    end
    it "protects #updated_at" do
      saved_attrs = question.attributes
      if defined? ActiveModel::MassAssignmentSecurity::Error
        expect { question.update_attributes(:updated_at => 3.hours.ago) }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
      else
        question.attributes = {:updated_at => 3.hours.ago} # Rails doesn't return false, but this will be checked in the comparison to saved_attrs
      end
      question.attributes.should == saved_attrs
    end
  end

  describe '#corresponding_requirements' do
    it 'saves and restores as an Array' do
      question = FactoryGirl.create(:question, corresponding_requirements: ['basic_1', 'standard_10'])
      question = Question.find(question.id)
      expect(question.corresponding_requirements).to eql(['basic_1', 'standard_10'])
    end
  end

  context "with answers" do
    let(:answer_1){ FactoryGirl.create(:answer, :question => question, :display_order => 3, :text => "blue")}
    let(:answer_2){ FactoryGirl.create(:answer, :question => question, :display_order => 1, :text => "red")}
    let(:answer_3){ FactoryGirl.create(:answer, :question => question, :display_order => 2, :text => "green")}
    before do
      [answer_1, answer_2, answer_3].each{|a| question.answers << a }
    end
    it{ question.should have(3).answers}
    it "gets answers in order" do
      question.answers.should == [answer_2, answer_3, answer_1]
      question.answers.map(&:display_order).should == [1,2,3]
    end
    it "deletes child answers when deleted" do
      answer_ids = question.answers.map(&:id)
      question.destroy
      answer_ids.each{|id| Answer.find_by_id(id).should be_nil}
    end
  end

  context "with dependencies" do
    let(:response_set){ FactoryGirl.create(:response_set, survey: question.survey) }
    let(:dependency){ FactoryGirl.create(:dependency) }
    before do
      question.dependency = dependency
    end
    it "checks its dependency" do
      question.triggered?(response_set).should be_false
    end
    it "deletes its dependency when deleted" do
      d_id = question.dependency.id
      question.destroy
      Dependency.find_by_id(d_id).should be_nil
    end
  end

  context "with mustache text substitution" do
    require 'mustache'
    let(:mustache_context){ Class.new(::Mustache){ def site; "Northwestern"; end; def foo; "bar"; end } }
    it "subsitutes Mustache context variables" do
      question.text = "You are in {{site}}"
      question.in_context(question.text, mustache_context).should == "You are in Northwestern"
    end
    it "substitues in views" do
      question.text = "You are in {{site}}"
      question.text_for(nil, mustache_context).should == "You are in Northwestern"
    end
  end

  context "handling strings" do
    it "#split preserves strings" do
      question.split(question.text).should == "What is your favorite color?"
    end
    it "#split(:pre) preserves strings" do
      question.split(question.text, :pre).should == "What is your favorite color?"
    end
    it "#split(:post) preserves strings" do
      question.split(question.text, :post).should == ""
    end
    it "#split splits strings" do
      question.text = "before|after|extra"
      question.split(question.text).should == "before|after|extra"
    end
    it "#split(:pre) splits strings" do
      question.text = "before|after|extra"
      question.split(question.text, :pre).should == "before"
    end
    it "#split(:post) splits strings" do
      question.text = "before|after|extra"
      question.split(question.text, :post).should == "after|extra"
    end
  end

  context "for views" do
    let(:asset_directory){ asset_pipeline_enabled? ? "assets" : "images" }
    before do
      ActionController::Base.helpers.config.assets_dir = "public" unless asset_pipeline_enabled?
    end
    it "#text_for with #display_type == image" do
      question.text = "rails.png"
      question.display_type = :image
      question.text_for.should == %(<img alt="Rails" src="/#{asset_directory}/rails.png" />)
    end
    it "#help_text_for"
    it "#text_for preserves strings" do
      question.text_for.should == "What is your favorite color?"
    end
    it "#text_for(:pre) preserves strings" do
      question.text_for(:pre).should == "What is your favorite color?"
    end
    it "#text_for(:post) preserves strings" do
      question.text_for(:post).should == ""
    end
    it "#text_for splits strings" do
      question.text = "before|after|extra"
      question.text_for.should == "before|after|extra"
    end
    it "#text_for(:pre) splits strings" do
      question.text = "before|after|extra"
      question.text_for(:pre).should == "before"
    end
    it "#text_for(:post) splits strings" do
      question.text = "before|after|extra"
      question.text_for(:post).should == "after|extra"
    end
  end
end
