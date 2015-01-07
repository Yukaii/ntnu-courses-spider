require 'json'
require 'rest_client'
require 'nokogiri'
require 'ruby-progressbar'

url = "http://courseap.itc.ntnu.edu.tw/acadmOpenCourse/CofopdlCtrl"
sys_ctrl = "http://courseap.itc.ntnu.edu.tw/acadmOpenCourse/SyllabusCtrl"

def prepare_url_params department, year=103, term=1, language='chinese'
  {
    :acadmYear => year,
    :acadmTerm => term,
    :deptCode => department,
    :language => language,
    :action => 'showGrid',
    :start => 0,
    :limit => 99999,
    :page => 1
  }
end

redos = 0
courses = []

departments = JSON.parse(File.read('departments.json'))
progressbar = ProgressBar.create(:total => departments.keys.count)
departments.keys.each_with_index do |dep_code, index|
  begin
    r = RestClient.get url, :params => prepare_url_params(dep_code)
  rescue
    if redos == 5
      redos = 0
      next
    else
      redos ++
      sleep(3)
      redo
    end
  end
  progressbar.increment
  raw = JSON.parse(r.to_s)
  item_progress = ProgressBar.create(:title => "item", :total => raw["List"].count)
  raw["List"].each do |c|
    get_params = {
      :year => c["acadm_year"],
      :term => c["acadm_term"],
      :courseCode => c["course_code"],
      :courseGroup => c["course_group"],
      :formS => c["form_s"],
      :classes1 => c["classes"],
      :deptCode => c["dept_code"],
      :deptGroup => c["dept_group"],
      :language2 => ""
    }

    begin
      r = RestClient.get sys_ctrl, :params => get_params
      doc = Nokogiri::HTML(r.to_s)
      book_row = doc.css('tr:contains("參考書目")')
      c["book"] = book_row.css('td').last.text if book_row.count != 0      
    rescue Exception => e
      c["book"] = nil
    end
    item_progress.increment
    courses << c
  end
end

File.open('courses.json', 'w') { |f| f.write(JSON.pretty_generate(courses)) }