require 'rails_helper'

feature 'Letters' do
  let(:officer) { create(:poll_officer, letter_officer: true) }
  let(:poll)    { create(:poll) }

  background do
    login_as(officer.user)
    visit new_officing_letter_path

    allow_any_instance_of(Officing::Residence).
    to receive(:letter_poll).and_return(poll)
  end

  scenario "Verify and store voter" do
    select 'DNI', from: 'residence_document_type'
    fill_in 'residence_document_number', with: "12345678Z"
    fill_in 'residence_postal_code', with: '28013'

    click_button 'Validate document'

    expect(page).to have_content 'Valid vote'

    voters = Poll::Voter.all
    expect(voters.count).to eq(1)
    expect(voters.first.origin).to eq("letter")
    expect(voters.first.document_number).to eq("12345678Z")
    expect(voters.first.document_type).to eq("1")
    expect(voters.first.poll).to eq(poll)
  end

  scenario "Error on verify" do
    click_button 'Validate document'
    expect(page).to have_content(/\d errors? prevented the verification of this document/)
  end

  scenario "Error on Census (document number)" do
    initial_failed_census_calls_count = officer.failed_census_calls_count
    visit new_officing_letter_path

    select 'DNI', from: 'residence_document_type'
    fill_in 'residence_document_number', with: "9999999A"
    fill_in 'residence_postal_code', with: '28013'

    click_button 'Validate document'

    expect(page).to have_content 'The Census was unable to verify this document'

    officer.reload
    fcc = FailedCensusCall.last
    expect(fcc).to be
    expect(fcc.poll_officer).to eq(officer)
    expect(officer.failed_census_calls.last).to eq(fcc)
    expect(officer.failed_census_calls_count).to eq(initial_failed_census_calls_count + 1)
  end

  scenario "Error on Census (postal code)" do
    select 'DNI', from: 'residence_document_type'
    fill_in 'residence_document_number', with: "12345678Z"
    fill_in 'residence_postal_code', with: '28014'

    click_button 'Validate document'

    expect(page).to have_content 'The Census was unable to verify this document'
  end

  scenario "Error already voted" do
    poll = create(:poll)
    user = create(:user, document_number: "12345678Z")
    create(:poll_voter, user: user, poll: poll)

    allow_any_instance_of(Officing::Residence).
    to receive(:letter_poll).and_return(poll)

    select 'DNI', from: 'residence_document_type'
    fill_in 'residence_document_number', with: "12345678Z"
    fill_in 'residence_postal_code', with: '28013'

    click_button 'Validate document'

    expect(page).to_not have_content 'The Census was unable to verify this document'
    expect(page).to have_content '1 error prevented the verification of this document'
    expect(page).to have_content 'Vote Reformulated'
  end

  context "Permissions" do

    scenario "Non officers can not access letter interface" do
      user = create(:user)

      login_as(user)
      visit new_officing_letter_path

      expect(page).to have_content "You do not have permission to access this page"
    end

    scenario "Standard officers can not access letter interface" do
      officer = create(:poll_officer)

      login_as(officer.user)
      visit new_officing_letter_path

      expect(page).to have_content "You do not have permission to access this page"
    end

    scenario "Letter officers can access letter interface" do
      officer = create(:poll_officer, letter_officer: true)

      login_as(officer.user)
      visit new_officing_letter_path

      expect(page).to have_content 'Validate document'
    end

    scenario "Admins can access letter interface" do
      admin = create(:administrator)

      login_as(admin.user)
      visit new_officing_letter_path

      expect(page).to have_content 'Validate document'
    end

  end

end