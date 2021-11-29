require 'curb'
require 'nokogiri'
require 'open-uri'
require 'csv'

def scanpages(category)
  n = 2
  http = Curl.get(category)
  puts http.url
  scangoods(Nokogiri::HTML(http.body_str))
  loop do
    http = Curl.get(category+"?p=#{n}")
    if http.header_str.include? "HTTP/2 302"
      break
    end
    puts http.url
    scangoods(Nokogiri::HTML(http.body_str))
    n = n + 1
  end
end

def scangoods(listofgoods)
  (0..(listofgoods.xpath("//a[@class='product_img_link pro_img_hover_scale product-list-category-img']").count - 1)).each { |i|
    puts listofgoods.xpath("//a[@class='product_img_link pro_img_hover_scale product-list-category-img']")[i]['href']
    pagehttp = Curl.get(listofgoods.xpath("//a[@class='product_img_link pro_img_hover_scale product-list-category-img']")[i]['href'])
    getdetails(Nokogiri::HTML(pagehttp.body_str))
    puts "\n"
  }
end

def getdetails(page)
  page.xpath("//h1[@class='product_main_name']").each do |node|
    if page.xpath("//span[@class='radio_label']").count > 0
      getdetailswithoptions(page, node)
    else
      getdetailswithoutoptins(page, node)
    end
  end
  puts "End"
end

def getdetailswithoptions(page, node)
  (0..(page.xpath("//span[@class='radio_label']").count - 1)).each { |n|
    puts node.text.lstrip + " " + page.xpath("//span[@class='radio_label']")[n].text
    puts page.xpath("//span[@class='price_comb']")[n].text
    puts page.xpath("//img[@id='bigpic']")[0]['src'] + "\n"
    writetofile(node.text.lstrip + " " + page.xpath("//span[@class='radio_label']")[n].text, page.xpath("//span[@class='price_comb']")[n].text, page.xpath("//img[@id='bigpic']")[0]['src'])
  }
end

def getdetailswithoutoptins(page, node)
  puts node.text
  puts page.xpath("//span[@id='our_price_display']").text
  puts page.xpath("//img[@id='bigpic']")[0]['src']+"\n"
  writetofile(node.text, page.xpath("//span[@id='our_price_display']").text, page.xpath("//img[@id='bigpic']")[0]['src'])
end

def writetofile(nameofgood, priceofgood, imageofgood)
  $csv << [nameofgood, priceofgood, imageofgood]
end

def makedoc
  csv = CSV.open($filename+".csv", "w")
  csv << %w(Name Price Image)
  $csv = CSV.open($filename+".csv", "a")
end

puts "Enter link"
page = gets.chomp
puts "Enter file name"
$filename = gets.chomp
makedoc
scanpages(page)

