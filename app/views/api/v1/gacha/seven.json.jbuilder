json.pulls @result.pulls do |pull|
  json.hit pull[:hit]
  if pull[:monster]
    json.monster do
      json.name pull[:monster].name
      json.sprite_key pull[:monster].sprite_key
    end
  else
    json.monster nil
  end
end
json.rainbow_coins @user.rainbow_coins
