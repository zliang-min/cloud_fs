# -- encoding: utf-8 --

#require_relative 'helper'
require 'pathname'
require 'digest/md5'

#require Pathname(__FILE__).dirname.join('helper')
require 'helper'

# TODO I need a helper to test the same things in POST & PUT

share_as 'SuccessGet' do
  subject { last_response }
  its(:status) { should be 200 }
  its(:content_type) { should == 'image/gif' }

  it 'should have a correct ETag header.' do
    subject.headers['ETag'].should == %("#{Digest::MD5.hexdigest(File.read(empty_gif))}")
  end

  it 'should have the Last-Modifed header.' do
    subject.headers['Last-Modified'].should_not be_nil
    subject.headers['Last-Modified'].should_not be_empty
  end

  it 'should have a Cache-Control header' do
    subject.headers['Cache-Control'].should_not be_nil
    subject.headers['Cache-Control'].should_not be_empty
  end

  its(:body) { Digest::MD5.hexdigest(subject).should == Digest::MD5.hexdigest(File.read(empty_gif)) }
end

describe CloudFS do
  include AssetsHelper

  context '使用GET来下载文件' do
    context '当id不是一个有效的BSON::ObjectId' do
      before(:all) { get '/invalid+object+id' }
      subject { last_response }
      its(:status) { should be 400 }
      its(:body) { Nokogiri::XML(subject).xpath('/error/code[text()="InvalidFileId"]').should_not be_empty }
    end

    context '当没有找到对应的文件' do
      before(:all) { get "/#{BSON::ObjectId.new}" }
      subject { last_response }
      its(:status) { should be 404 }
      its(:body) { Nokogiri::XML(subject).xpath('/error/code[text()="FileNotFound"]').should_not be_empty }
    end
  end

  context '通过POST方法保存文件' do
    context '参数验证' do
      context '必须提供file参数' do
        before { post '/' }

        subject { last_response }

        its(:status) { should be 400 }
        its(:content_type) { should == 'text/xml' }
        
        context 'response body' do
          subject { Nokogiri::XML last_response.body }
          
          it { subject.xpath('/error/code[text()="InvalidArgument"]').should_not be_empty }
          it { subject.xpath(%^/error/message[text()="Uploaded file was not supplied."]^).should_not be_empty }
        end
      end
    end

    context '成功保存文件后' do
      before(:all) { post '/', :file => Rack::Test::UploadedFile.new(empty_gif, 'image/gif') }

      subject { last_response }

      its(:status)  { should be 200 }
      its(:content_type)  { should == 'text/xml' }
      its(:headers) { should include 'ETAG' => md5_of_empty_gif }

      context 'response body' do
        subject { Nokogiri::XML last_response.body }

        specify { lambda { BSON::ObjectId.from_string subject.xpath('/response/id').text }.should_not raise_exception(BSON::InvalidObjectId) }
        specify { subject.xpath('/response/md5').text.should == md5_of_empty_gif }
      end

      context '通过GET获取保存后的文件' do
        context '通过header的response的id获取文件' do
          before(:all) { get "/#{Nokogiri::XML(last_response.body).xpath('/response/id').text}" }

          it_should_behave_like 'SuccessGet'
        end

        context '通过header的response的id加上文件后缀名获取文件' do
          before(:all) { get "/#{Nokogiri::XML(last_response.body).xpath('/response/id').text}.gif" }

          it_should_behave_like 'SuccessGet'
        end

        context '当使用不正确的后缀名获取文件' do
          before(:all) { get "/#{Nokogiri::XML(last_response.body).xpath('/response/id').text}.jpg" }
          specify { last_response.status.should be 404 }
        end

        context '通过header的response的id和md5获取文件' do
          before(:all) {
            body = Nokogiri::XML(last_response.body)
            get "/#{body.xpath('/response/id').text}-#{body.xpath('/response/md5').text}"
          }

          it_should_behave_like 'SuccessGet'
        end

        context '当使用不正确的md5获取文件' do
          before(:all) { get "/#{Nokogiri::XML(last_response.body).xpath('/response/id').text}-#{Digest::MD5.hexdigest 'it sucks'}" }
          specify { last_response.status.should be 404 }
        end

        context '通过header的response的id和md5加上文件后缀名获取文件' do
          before(:all) {
            body = Nokogiri::XML(last_response.body)
            get "/#{body.xpath('/response/id').text}-#{body.xpath('/response/md5').text}.gif"
          }

          it_should_behave_like 'SuccessGet'
        end

        context 'Get a thumbnail.' do
          context 'via a single size' do
            before {
              body = Nokogiri::XML(last_response.body)
              get "/#{body.xpath('/response/id').text}-#{body.xpath('/response/md5').text}_80.gif"
            }

            specify {
              img = Magick::Image.from_blob(last_response.body).first
              img.columns.should be 80
              img.rows.should be 80
              img.destroy!
            }
          end

          context 'with width and height' do
            before {
              body = Nokogiri::XML(last_response.body)
              get "/#{body.xpath('/response/id').text}-#{body.xpath('/response/md5').text}_60x30.gif"
            }

            specify {
              img = Magick::Image.from_blob(last_response.body).first
              # NOTE the image used in the test is 100 x 100
              img.columns.should be 30
              img.rows.should be 30
              img.destroy!
            }
          end
        end

      end
    end

    context '指定上传图片后把图片resize' do
      context '格式1' do
        before(:all) { post '/', :file => Rack::Test::UploadedFile.new(empty_gif, 'image/gif'), :resize => '90' }

        subject { last_response }

        its(:status)  { should be 200 }
        its(:content_type)  { should == 'text/xml' }

        context '取出来的文件' do
          before :all do
            body = Nokogiri::XML(last_response.body)
            get "/#{body.xpath('/response/id').text}-#{body.xpath('/response/md5').text}.gif"
          end

          it('should return a 200 response') { last_response.status.should be 200 }

          it "should be resized correctly." do
            img = Magick::Image.from_blob(last_response.body).first
            img.columns.should be 90
            img.rows.should be 90
            img.destroy!
          end
        end
      end

      context '格式2' do
        before(:all) { post '/', :file => Rack::Test::UploadedFile.new(empty_gif, 'image/gif'), :resize => '50x40' }

        subject { last_response }

        its(:status)  { should be 200 }
        its(:content_type)  { should == 'text/xml' }

        context '取出来的文件' do
          before :all do
            body = Nokogiri::XML(last_response.body)
            get "/#{body.xpath('/response/id').text}-#{body.xpath('/response/md5').text}.gif"
          end

          it('should return a 200 response') { last_response.status.should be 200 }

          it "should be resized correctly." do
            img = Magick::Image.from_blob(last_response.body).first
            img.columns.should be 40
            img.rows.should be 40
            img.destroy!
          end
        end
      end

      context '当大小超过原来图片的大小时' do
        before(:all) { post '/', :file => Rack::Test::UploadedFile.new(empty_gif, 'image/gif'), :resize => '200' }

        subject { last_response }

        its(:status)  { should be 200 }
        its(:content_type)  { should == 'text/xml' }

        context '取出来的文件' do
          before :all do
            body = Nokogiri::XML(last_response.body)
            get "/#{body.xpath('/response/id').text}-#{body.xpath('/response/md5').text}.gif"
          end

          it('should return a 200 response') { last_response.status.should be 200 }

          it "should not be resized." do
            img = Magick::Image.from_blob(last_response.body).first
            img.columns.should be 100
            img.rows.should be 100
            img.destroy!
          end
        end
      end
    end

    it { pending 'should support 100-continue' }
  end

  context '通过PUT方法保存文件' do
    context '验证Content-MD5头' do
      context '当MD5与文件内容不符' do
        before(:all)  {
          put '/empty.gif', File.read(empty_gif),
            'Content-MD5' => Base64.encode64(Digest::MD5.hexdigest('mal-content')),
            'Content-Type' => 'image/gif'
        }

        subject { last_response }

        its(:status) { should be 400 }
        its(:content_type) { should == 'text/xml' }

        context 'response body' do
          subject { Nokogiri::XML last_response.body }

          # I wish I could use Webrat mather have_xpath, but it doesn't work well with xml body.
          it { subject.xpath('/error/code[text()="BadDigest"]').should_not be_empty }
          it { subject.xpath('/error/resource[text()="/empty.gif"]').should_not be_empty }
        end
      end

      context '当MD5与文件内容一致' do
        before(:all)  {
          put "/empty.gif", File.read(empty_gif),
            'Content-MD5' => Base64.encode64(md5_of_empty_gif),
            'Content-Type' => 'image/gif'
        }

        specify { last_response.status.should be 204 }
      end
    end
  end

  context '当使用GET获取文件' do
    context '文件是静态文件时' do
      before :all do
        @static_file = File.join CloudFS.public_directory, 'static_file.txt'
        unless File.file?(@static_file)
          File.open(@static_file, 'w') { |f| f << 'a static file.' }
          @generate_static_file = true
        end

        get '/static_file.txt'
      end

      after :all do
        if @generate_static_file
          require 'fileutils'
          FileUtils.rm_f @static_file
        end
      end

      specify { last_response.body.should == File.read(@static_file) }
    end
  end
end
