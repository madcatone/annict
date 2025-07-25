# typed: false
# frozen_string_literal: true

RSpec.describe "POST /v1/me/records", type: :request do
  it "正常なデータで記録を作成できること" do
    user = create(:user, :with_profile, :with_setting)
    application = create(:oauth_application, owner: user)
    access_token = create(:oauth_access_token, application: application)
    work = create(:work, :with_current_season)
    episode = create(:episode, work: work)

    expect(EpisodeRecord.count).to eq 0
    expect(Record.count).to eq 0
    expect(ActivityGroup.count).to eq 0
    expect(Activity.count).to eq 0

    data = {
      episode_id: episode.id,
      comment: "あぁ^～心がぴょんぴょんするんじゃぁ^～",
      rating: 4.5,
      rating_state: "great",
      access_token: access_token.token
    }
    post api("/v1/me/records", data)

    expect(response.status).to eq(200)

    expect(EpisodeRecord.count).to eq 1
    expect(Record.count).to eq 1
    expect(ActivityGroup.count).to eq 1
    expect(Activity.count).to eq 1

    episode_record = user.episode_records.first
    record = user.records.first
    activity_group = user.activity_groups.first
    activity = user.activities.first

    expect(episode_record.body).to eq data[:comment]
    expect(episode_record.locale).to eq "ja"
    expect(episode_record.rating).to eq data[:rating]
    expect(episode_record.rating_state).to eq data[:rating_state]
    expect(episode_record.episode_id).to eq episode.id
    expect(episode_record.record_id).to eq record.id
    expect(episode_record.work_id).to eq work.id

    expect(record.work_id).to eq work.id

    expect(activity_group.itemable_type).to eq "EpisodeRecord"
    expect(activity_group.single).to eq true

    expect(activity.activity_group_id).to eq activity_group.id
    expect(activity.itemable).to eq episode_record

    expect(json["id"]).to eq episode_record.id
    expect(json["comment"]).to eq data[:comment]
    expect(json["rating"]).to eq data[:rating]
    expect(json["rating_state"]).to eq data[:rating_state]
  end

  it "無効なデータの場合、エラーが返されること" do
    user = create(:user, :with_profile, :with_setting)
    application = create(:oauth_application, owner: user)
    access_token = create(:oauth_access_token, application: application)
    work = create(:work, :with_current_season)
    episode = create(:episode, work: work)

    data = {
      episode_id: episode.id,
      comment: "a" * (Record::MAX_BODY_LENGTH + 1), # 長すぎるコメント
      rating: 4.5,
      rating_state: "great",
      access_token: access_token.token
    }
    post api("/v1/me/records", data)

    expect(response.status).to eq(400)

    expected = {
      errors: [
        {
          type: "invalid_params",
          message: "感想は1048596文字以内で入力してください"
        }
      ]
    }
    expect(json).to include(expected.deep_stringify_keys)
  end

  it "認証トークンがない場合、エラーが返されること" do
    work = create(:work, :with_current_season)
    episode = create(:episode, work: work)

    data = {
      episode_id: episode.id,
      comment: "テストコメント",
      rating: 4.5,
      rating_state: "great"
    }
    post api("/v1/me/records", data)

    expect(response.status).to eq(401)
  end

  it "存在しないエピソードIDの場合、エラーが返されること" do
    user = create(:user, :with_profile, :with_setting)
    application = create(:oauth_application, owner: user)
    access_token = create(:oauth_access_token, application: application)

    data = {
      episode_id: "invalid_id",
      comment: "テストコメント",
      rating: 4.5,
      rating_state: "great",
      access_token: access_token.token
    }
    post api("/v1/me/records", data)

    expect(response.status).to eq(400)
  end
end
