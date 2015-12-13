describe "query", :fake_api do
  before { stub_request :any, /localhost/ }

  let(:client) do
    Evil::Client
      .new("http://localhost/")
      .query(foo: :bar)
      .query(bar: :baz)
  end

  context "in GET request" do
    before  { client.get baz: :qux }
    subject { a_request(:get, "http://localhost?foo=bar&bar=baz&baz=qux") }

    it { is_expected.to have_been_made }
  end

  context "in POST request" do
    before  { client.post baz: :qux }
    subject { a_request(:post, "http://localhost?foo=bar&bar=baz") }

    it { is_expected.to have_been_made }
  end
end
