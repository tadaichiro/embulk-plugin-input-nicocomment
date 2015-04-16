module Embulk
  module Input
    class InputNicoComment < InputPlugin
      Plugin.register_input('nicocomment', self)

      def self.transaction(config, &control)
        
        threads = 1
        id = config.param('id', :string)
        password = config.param('password', :string)
        term = config.param('term', :string, default: 'hourly')
        target = config.param('target', :string, default: 'fav')
        category = config.param('category', :string, default: 'all')

        task = {'id' => id, 'password' => password, 'term' => term, 'target' => target, 'category' => category}

        columns = [
          Column.new(0, 'smid', :string),
          Column.new(1, 'comment', :string),
          Column.new(2, 'date', :timestamp)
        ]

        puts "File information generation started."
        commit_reports = yield(task, columns, threads)
        puts "File information input finished."

        return {}

      end

      def initialize(task, schema, index, page_builder)
        super
      end

      def run

        require 'net/https'
        require 'rexml/document'
        require 'json'

        id = @task['id']
        password = @task['password']
        term = @task['term']
        target = @task['target']
        category = @task['category']

        cookie = login_nicovideo(id, password)
        smids = get_ranking(cookie, term, target, category)
        thread_info = get_flv_info(cookie, smids)
        com_info = get_comments(cookie, thread_info)

        com_info.each { |com|
          begin
            if com['id'] != nil
                @page_builder.add([com['id'], com['content'], com['date']])
            end
          rescue
          end
        }

        @page_builder.finish

        commit_report = {
        }
        return commit_report
      end

      def login_nicovideo(mail, pass)
        host = 'secure.nicovideo.jp'
        path = '/secure/login?site=niconico'
        body = "mail=#{mail}&password=#{pass}"

        https = Net::HTTP.new(host, 443)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = https.start { |https|
          https.post(path, body)
        }

        cookie = ''
        response['set-cookie'].split('; ').each do |st|
          if idx = st.index('user_session_')
            cookie = "user_session=#{st[idx..-1]}"
            break
          end
        end

        return cookie
      end

      def get_response(host ,path, watitime, cookie)

        sleep(watitime)
        response = Net::HTTP.new(host).start { |http|
          request = Net::HTTP::Get.new(path)
          request['cookie'] = cookie
          http.request(request)
        }

        return response
      end

      def http_response(host, path, cookie)

        response = get_response(host, path ,3, cookie)
          
        if response.body.include?("error")
          response = get_response(host, path ,30, cookie)
        end

        return response
      end

      def get_ranking(cookie, term, target, category)

        host = 'www.nicovideo.jp'
        path = "/ranking/#{target}/#{term}/#{category}?rss=2.0"

        response = http_response(host, path, cookie)

        doc = REXML::Document.new response.body
        smids = []
        doc.elements.each('/rss/channel/item/link'){|e| smids << e.text.split('/').last}
        return smids
      end

      def get_flv_info(cookie, smids)
        host = 'flapi.nicovideo.jp'
        ret = []
        
        smids.each { |sm|
          path = "/api/getflv/#{sm}"
          response = http_response(host, path, cookie)
          
          flv_info = {}
          flv_info[:sm] = sm
          response.body.split('&').each do |st|
            stt = st.split('=')

            if stt[0] == 'thread_id'
              flv_info[:thread_id] = stt[1]
            end

            if stt[0] == 'ms'
              flv_info[:ms] = stt[1].split('%2F')[3]
            end
          end

        ret << flv_info
        }
        return ret
      end

      def get_comments(cookie, thread_info)
        host = 'msg.nicovideo.jp'
        ret = []

        thread_info.each { |ar|

          thread_val = ar[:thread_id]
          ms = ar[:ms]
          next if ms == nil

          path = "/#{ms}/api.json/thread?version=20090904&thread=#{thread_val}&res_from=-1000"
          
          begin
            response = http_response(host, path, cookie)
          
            JSON.load(response.body).each { |js|
              comjs = js['chat']
              if comjs != nil
                com_info = {}
                com_info['id'] = ar[:sm]
                com_info['content'] = comjs['content']
                com_info['date'] = Time.at(comjs['date'])
                ret << com_info
              end
            }
          rescue
          end
        }

        return ret
      end
    end
  end
end