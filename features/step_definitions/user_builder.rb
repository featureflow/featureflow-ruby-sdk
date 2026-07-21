require "featureflow"

Given(/^there is access to the User Builder module$/) do
  expect(Featureflow::UserBuilder).to be
end

When(/^the builder is initialised with the id "([^"]*)"$/) do |id|
  begin
    @builder = Featureflow::UserBuilder.new(id)
  rescue => e
    @error = e
  end
end

And(/^the user is built using the builder$/) do
  @user = @builder.build
end

Then(/^the result user should have an id "([^"]*)"$/) do |id|
  expect(@user[:id]).to eq(id)
end

And(/^the builder is given the following attributes$/) do |values|
  hashes = {}
  values.hashes.each do |hash|
    hashes[hash['key']] = hash['value']
  end
  @builder.with_attributes(hashes)
end

Then(/^the result user should have no attributes$/) do
  expect(@user[:attributes].keys.length).to eq(0)
end

Then(/^the result user should have a attribute with key "([^"]*)" and value "([^"]*)"$/) do |key, value|
  expect(@user[:attributes][key].to_s).to eq(value)
end

Then(/^the result user should not have a attribute with key "([^"]*)"$/) do |key|
  expect(@user[:attributes]).not_to have_key(key)
end

Then(/^the builder should throw an error$/) do
  expect(@error).to be
end
