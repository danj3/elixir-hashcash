Here are some test resources:

1:16:220902:testcase-resource::3hVEhwDtcJtpd6q0UIwhJCeLZH6ykoG
1:16:220902:testcase-resource::/t5MiwxP9p4Aebl7o0c9C7LebKUbiVi
1:16:220902:testcase-resource::eH1s4fyhThkkn5STOvbkvw7Oe1Rpc8J
1:16:220902:testcase-resource::H05w4Lo6WS2/0BkEmwJcHTNtlq2iPLv
1:16:220902:testcase-resource::CheQe4xfXH56n6gmkyxwdhn/zcRQ6GD

A JS console session:

<pasted in hashcash.js>

>> await hashcash.generate("1:16:220902:testcase-resource::3hVEhwDtcJtpd6q0UIwhJCeLZH6ykoG")
"1:16:220902:testcase-resource::3hVEhwDtcJtpd6q0UIwhJCeLZH6ykoG:14891"

>> await hashcash.generate("1:16:220902:testcase-resource::/t5MiwxP9p4Aebl7o0c9C7LebKUbiVi")
"1:16:220902:testcase-resource::/t5MiwxP9p4Aebl7o0c9C7LebKUbiVi:40079"

>> await hashcash.generate("1:16:220902:testcase-resource::eH1s4fyhThkkn5STOvbkvw7Oe1Rpc8J")
"1:16:220902:testcase-resource::eH1s4fyhThkkn5STOvbkvw7Oe1Rpc8J:34379"

>> await hashcash.generate("1:16:220902:testcase-resource::H05w4Lo6WS2/0BkEmwJcHTNtlq2iPLv")
"1:16:220902:testcase-resource::H05w4Lo6WS2/0BkEmwJcHTNtlq2iPLv:37040"

>> await hashcash.generate("1:16:220902:testcase-resource::CheQe4xfXH56n6gmkyxwdhn/zcRQ6GD")
"1:16:220902:testcase-resource::CheQe4xfXH56n6gmkyxwdhn/zcRQ6GD:738"
