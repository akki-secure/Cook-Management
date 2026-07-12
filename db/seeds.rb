%w[和食 洋食 中華 イタリアン デザート スープ サラダ その他].each do |name|
  Category.find_or_create_by!(name: name)
end
