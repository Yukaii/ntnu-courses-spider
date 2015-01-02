require 'json'
require 'rest_client'
require 'ruby-progressbar'

url = "http://courseap.itc.ntnu.edu.tw/acadmOpenCourse/CofopdlCtrl"

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

courses = []

departments = JSON.parse(File.read('departments.json'))
progressbar = ProgressBar.create(:total => departments.keys.count)
departments.keys.each_with_index do |dep_code, index|
  r = RestClient.get url, :params => prepare_url_params(dep_code)
  progressbar.increment
  raw = JSON.parse(r.to_s)

  raw["List"].each {|c| courses << c}
end

File.open('courses.json', 'w') { |f| f.write(JSON.pretty_generate(courses)) }