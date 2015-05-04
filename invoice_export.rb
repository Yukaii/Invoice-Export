require 'csv';

def print_table_header(csv)
  # 發票張數 發票日期 品名序號 發票品名 數量 單價 課稅別 稅率 通關方式 買方統編 列印+Email 手機條碼 自然人 愛心碼 會員類別 會員號碼 貨號 國際條碼 發票備註欄位 交易明細備註欄位
  csv << []; # empty line
  csv << %w(發票張數 發票日期 品名序號 發票品名 數量 單價 課稅別 稅率 通關方式 買方統編 列印+Email 手機條碼 自然人 愛心碼 會員類別 會員號碼 貨號 國際條碼 發票備註欄位 交易明細備註欄位);
end

def mkcd dirname
  Dir.mkdir(dirname); Dir.chdir(dirname);
end

Dir.chdir('tmp');
today_str = "#{Time.now.strftime('%F').gsub(/\-/, '')}"
mkcd("invoice");
mkcd("invoice#{Time.now.strftime('%F-%T')}");

csv_count = 0
csv = nil

Bill.where(state: :paid).each_with_index do |bill, invoice_index|
  book_h = {};
  user = bill.user
  invoice_count = bill.orders.map(&:book_name).uniq.count
  invoice_count += 1 if bill.amount != bill.price
  today = Time.now.strftime('%F')

  bill.orders.each do |order|
    (book_h[order.book_id].nil?) ? book_h[order.book_id] = 1 : book_h[order.book_id] += 1;
  end

  if invoice_index % 50 == 0
    csv_count += 1
    csv = CSV.open("invoice-#{today_str}-#{csv_count}.csv", 'w');
    print_table_header(csv);
  end

  if bill.amount < (bill.price)
    # if row_count >= 42
    #   row_count = 0
    #   csv_count += 1
    #   csv = CSV.open("invoice-#{today_str}-#{csv_count}.csv", 'w');
    #   print_table_header(csv);
    # end
    # 有折抵
    account_type = "EJ0103";
    account_code = "#{user.id}";
    # serial_no = book.isbn;
    serial_no = "";
    international_code = "";
    invoice_note = "#{user.name}";
    transanction_note = bill.id;
    invoice_uni_num_print = "";
    csv << [(invoice_index%50 + 1), today, 1, "已折抵書錢", 1, bill.amount, "1", "0.05", "", "", "", "", "", "", "#{account_type}", "#{account_code}", "#{serial_no}", "#{international_code}", "#{invoice_note}", "#{transanction_note}"];
  else
    book_h.each_with_index do |(book_id, amount), order_index|
      begin
        book = nil
        book = Book.find_by_id(book_id);
        if book.nil?
          book = Book.with_deleted.find_by_id(book_id)
          message = "deleted";
        end

        account_type = "EJ0103";
        account_code = "#{user.id}";
        # serial_no = book.isbn;
        serial_no = "";
        international_code = "";
        invoice_note = "#{user.name}";
        transanction_note = bill.id;
        invoice_uni_num_print = "";
        csv << [(invoice_index%50 + 1), today, order_index+1, book.name, amount, book.price, "1", "0.05", "", bill.invoice_uni_num, "#{invoice_uni_num_print}",bill.invoice_code, bill.invoice_cert, bill.invoice_love_code, "#{account_type}", "#{account_code}", "#{serial_no}", "#{international_code}", "#{invoice_note}", "#{transanction_note}#{message}"];

        if book_h.count == order_index+1
          # print 35
          # if row_count % 45 == 0
          #   csv = CSV.open("invoice-#{today_str}-#{csv_count}.csv", 'w');
          #   print_table_header(csv);
          #   row_count = 0
          #   csv_count += 1
          # end

          if bill.amount == (bill.price + 35)
            csv << [(invoice_index%50 + 1), today, invoice_count, "手續費", 1, 35, "1", "0.05", "", "", "", "", "", "", "#{account_type}", "#{account_code}", "#{serial_no}", "#{international_code}", "#{invoice_note}", "#{transanction_note}"];
          # elsif bill.amount < (bill.price)
          #   csv << [invoice_index+1, today, invoice_count, "折抵", 1, bill.price - bill.amount, "1", "0.05", "", "", "", "", "", "", "#{account_type}", "#{account_code}", "#{serial_no}", "#{international_code}", "#{invoice_note}", "#{transanction_note}"];
          #   row_count += 1
          end
        end
      rescue Exception => e
        next
      end
    end
  end
end
