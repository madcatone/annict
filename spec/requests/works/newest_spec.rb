# typed: false
# frozen_string_literal: true

RSpec.describe "GET /works/newest", type: :request do
  it "アクセスできること" do
    work = create(:work)

    get "/works/newest"

    expect(response.status).to eq(200)
    expect(response.body).to include(work.title)
  end

  it "削除されていない作品のみを表示すること" do
    kept_work = create(:work)
    deleted_work = create(:work, deleted_at: Time.current)

    get "/works/newest"

    expect(response.body).to include(kept_work.title)
    expect(response.body).not_to include(deleted_work.title)
  end

  it "新しい作品から順に表示すること" do
    old_work = create(:work)
    new_work = create(:work)

    get "/works/newest"

    expect(response.body.index(new_work.title)).to be < response.body.index(old_work.title)
  end

  it "グリッド表示（デフォルト）で30件表示すること" do
    create_list(:work, 31)

    get "/works/newest"

    # 各作品のリンクでカウント
    expect(response.body.scan(%r{<div class="c-work-card}).count).to eq(30)
  end

  it "display=gridで30件表示すること" do
    create_list(:work, 31)

    get "/works/newest", params: {display: "grid"}

    expect(response.body.scan(%r{<div class="c-work-card}).count).to eq(30)
  end

  it "display=grid_smallで120件表示すること" do
    create_list(:work, 121)

    get "/works/newest", params: {display: "grid_small"}

    expect(response.body.scan(%r{<div class="c-work-grid__col}).count).to eq(120)
  end

  it "無効なdisplayパラメータの場合はグリッド表示（30件）にすること" do
    create_list(:work, 31)

    get "/works/newest", params: {display: "invalid"}

    expect(response.body.scan(%r{<div class="c-work-card}).count).to eq(30)
  end

  it "ページネーションが動作すること" do
    create_list(:work, 35)

    get "/works/newest", params: {page: 2}

    expect(response.status).to eq(200)
    expect(response.body.scan(%r{<div class="c-work-card}).count).to eq(5)
  end
end
