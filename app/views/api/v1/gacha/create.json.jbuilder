json.hit @result.hit
if @result.monster
  json.monster do
    json.name @result.monster.name
    json.sprite_key @result.monster.sprite_key
  end
else
  json.monster nil
end
json.coins @user.coins
