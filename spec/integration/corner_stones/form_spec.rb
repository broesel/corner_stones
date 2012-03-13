require 'integration/spec_helper'

require 'corner_stones/form'
require 'corner_stones/form/with_inline_errors'

describe CornerStones::Form do

  given_the_html <<-HTML
    <form action="/articles" method="post" class="article-form">
      <label for="title">Title</label>
      <input type="text" name="title" id="title">

      <label for="author">Author</label>
      <select name="author" id="author">
        <option value="1">Robert C. Martin</option>
        <option value="2">Eric Evans</option>
        <option value="3">Kent Beck</option>
      </select>

      <label for="body">Body</label>
      <textarea name="body" id="body">
      </textarea>

      <label for="file">File</label>
      <input name="file" id="file" type="file">

      <input type="submit" name="button" value="Save">
      <input type="submit" name="button" value="Save Article">

    </form>
  HTML

  subject { CornerStones::Form.new('.article-form', :select_fields => ['Author'], :file_fields => ['File']) }

  it 'allows you to fill in the form' do
    subject.fill_in_with('Title' => 'Domain Driven Design',
                         'Author' => 'Eric Evans',
                         'Body' => '...',
                         'File' => 'spec/files/hadoken.png')

    find('#title').value.must_equal 'Domain Driven Design'
    find('#author').value.must_equal '2'
    find('#body').value.must_equal '...'
    find('#file').value.must_equal 'spec/files/hadoken.png'
  end

  it 'allows you to submit the form' do
    subject.submit

    current_path.must_equal '/articles'
    page.driver.request.post?.must_equal true
  end

  it 'you can supply the submit-button text with the :button option' do
    subject.submit(:button => 'Save Article')

    page.driver.request.params['button'].must_equal 'Save Article'
  end

  it 'allows you to process (fill_in_with + submit) the form' do
    subject.process(:fill_in => {
                      'Title' => 'Domain Driven Design',
                      'Author' => 'Eric Evans',
                      'Body' => 'Some Content...',
                      'File' => 'spec/files/hadoken.png'})

    current_path.must_equal '/articles'
    page.driver.request.post?.must_equal true

    page.driver.request.params.must_equal({"title" => "Domain Driven Design", "author" => "2", "body" => "Some Content...", "file" => "hadoken.png", 'button' => 'Save'})
  end

  it 'allows you to process (fill_in_with + submit) the form using an alternate button' do
    subject.process(:fill_in => {'Title' => 'Domain Driven Design',
                      'Author' => 'Eric Evans',
                      'Body' => 'Some Content...'},
                    :button => 'Save Article')

    page.driver.request.params['button'].must_equal('Save Article')
  end

  describe 'mixins' do
    describe 'form errors' do

      before do
        subject.extend(CornerStones::Form::WithInlineErrors)
      end

      describe 'with errors' do
        given_the_html <<-HTML
          <form action="/articles" method="post" class="form-with-errors article-form">
            <div>
              <label for="title">Title</label>
              <input type="text" name="title" id="title">
            </div>

            <div class="error">
              <label for="author">Author</label>
              <select name="author" id="author">
                <option value="1">Robert C. Martin</option>
                <option value="2">Eric Evans</option>
                <option value="3">Kent Beck</option>
              </select>
              <span class="help-inline">The author is not active</span>
            </div>

            <div class="error">
              <label for="body">Body</label>
              <textarea name="body" id="body">...</textarea>
              <span class="help-inline">invalid body</span>
            </div>

          <input type="submit" value="Save">

          </form>
        HTML

        it 'assembles the errors into a hash' do
          subject.errors.must_equal([{"Field" => "Author", "Value" => "1", "Error" => "The author is not active"},
                                     {"Field" => "Body", "Value" => "...", "Error" => "invalid body"}])
        end

        it '#assert_has_no_errors fails' do
          lambda do
            subject.assert_has_no_errors
          end.must_raise(CornerStones::Form::WithInlineErrors::FormHasErrorsError)
        end

        it 'does not allow you to submit the form by default' do
          lambda do
            subject.submit
          end.must_raise(CornerStones::Form::WithInlineErrors::FormHasErrorsError)
        end

        it 'bypass the auto-error-validation when passing :assert_valid => false' do
          subject.submit(:assert_valid => false)
        end
      end

      describe 'without errors' do
        given_the_html <<-HTML
          <form action="/articles" method="post" class="form-without-errors article-form">
            <label for="title">Title</label>
            <input type="text" name="title" id="title">

            <input type="submit" value="Save">
          <form>
        HTML
      end

      it '#assert_has_no_errors passes' do
        subject.assert_has_no_errors
      end

      it 'allows you to submit the form' do
        subject.submit
      end
    end
  end

  describe "#attributes" do
    given_the_html <<-HTML
      <form action="/articles" method="post" class="form-with-errors article-form">
        <div>
          <label>Ignored</label>
          <input type="text" name="ignored" id="ignored" value="I'm ignored" />
          <label for="title">Title</label>
          <input type="text" name="title" id="title" value="This is a title" />
          <label for="color">Color</label>
          <input type="color" name="color" id="color" value="This is a color" />
          <label for="date">Date</label>
          <input type="date" name="date" id="date" value="This is a date" />
          <label for="datetime">Datetime</label>
          <input type="datetime" name="datetime" id="datetime" value="This is a datetime" />
          <label for="datetime-local">Datetime-local</label>
          <input type="datetime-local" name="datetime-local" id="datetime-local" value="This is a datetime-local" />
          <label for="datetime-local">Datetime-local</label>
          <input type="datetime-local" name="datetime-local" id="datetime-local" value="This is a datetime-local" />
          <label for="email">Email</label>
          <input type="email" name="email" id="email" value="This is a email" />
          <label for="month">Month</label>
          <input type="month" name="month" id="month" value="This is a month" />
          <label for="number">Number</label>
          <input type="number" name="number" id="number" value="This is a number" />
          <label for="range">Range</label>
          <input type="range" name="range" id="range" value="This is a range" />
          <label for="search">Search</label>
          <input type="search" name="search" id="search" value="This is a search" />
          <label for="tel">Tel</label>
          <input type="tel" name="tel" id="tel" value="This is a tel" />
          <label for="time">Time</label>
          <input type="time" name="time" id="time" value="This is a time" />
          <label for="url">Url</label>
          <input type="url" name="url" id="url" value="This is a url" />
          <label for="week">Week</label>
          <input type="week" name="week" id="week" value="This is a week" />
          <label for="password">Password</label>
          <input type="password" name="password" id="password" value="This is a password" />
          <label for="description">Description</label>
          <textarea name="description" id="description">This is a description</textarea>
          <label for="author">Author</label>
          <select name="author" id="author">
            <option value="1">Robert C. Martin</option>
            <option value="2" selected>Eric Evans</option>
            <option value="3">Kent Beck</option>
          </select>
          <label for="is_happy">Happy?</label>
          <input type="checkbox" name="is_happy" id="is_happy" checked="checked" />
        </div>
        <input type="submit" value="Save">
      </form>
    HTML

    subject { CornerStones::Form.new('.article-form') }

    it "labels with no for-attribute are igrnored" do
      refute_includes(subject.attributes.values, "I'm ignored")
    end

    it "should return a hash of labels defined with for-attribute and the values of the connected fields" do
      subject.attributes.must_equal( {"Title" => "This is a title",
                                      "Color" => "This is a color",
                                      "Date" => "This is a date",
                                      "Datetime" => "This is a datetime",
                                      "Datetime-local" => "This is a datetime-local",
                                      "Email" => "This is a email",
                                      "Month" => "This is a month",
                                      "Number" => "This is a number",
                                      "Range" => "This is a range",
                                      "Search" => "This is a search",
                                      "Tel" => "This is a tel",
                                      "Time" => "This is a time",
                                      "Url" => "This is a url",
                                      "Week" => "This is a week",
                                      "Password" => "This is a password",
                                      "Description" => "This is a description",
                                      "Author" => "Eric Evans",
                                      "Happy?" => true})
    end

  end
end
